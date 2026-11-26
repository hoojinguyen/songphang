import { randomBytes } from "node:crypto";
import { z } from "@hono/zod-openapi";
import {
	type GuestGroupViewQuery,
	GuestGroupViewResponse,
	GuestLinkResponse,
	GuestToken,
	MemberColorCode,
	PaymentChannel,
	SplitInput,
	TransactionCategory,
} from "@songphang/contract";
import { groupTransferPurpose, transferPurpose } from "@songphang/core";
import {
	type AttachmentRow,
	findGroupByGuestToken,
	findGuestAttachment,
	fundCashAndContributions,
	insertActivity,
	listAttachmentsForTransactions,
	listGroupMembers,
	listGuestTransactionRows,
	listPaymentMethodsByGroup,
	listTransactionPayers,
	listTransactionShares,
	lockGroup,
	readGroupGuestLink,
	suggestGroupTransfers,
	updateGroupGuestLink,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { toAttachmentDto } from "./attachments.js";
import { buildPayToMethods } from "./balances.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { computeMemberBreakdownsIn } from "./member-breakdowns.js";
import { getSettlementCyclesIn } from "./settlement-cycles.js";
import {
	decodeTransactionCursor,
	encodeTransactionCursor,
} from "./transactions.js";

type MemberRow = Awaited<ReturnType<typeof listGroupMembers>>[number];
type GuestTxRow = Awaited<ReturnType<typeof listGuestTransactionRows>>[number];
type PaymentMethodsMap = Awaited<ReturnType<typeof listPaymentMethodsByGroup>>;
type TxAmountRow = { transactionId: string; memberId: string; amount: number };

function toGuestLinkDto(
	webOrigin: string,
	row: { active: boolean; token: string | null; createdAt: Date | null },
) {
	return {
		active: row.active,
		url: row.active && row.token ? `${webOrigin}/share/${row.token}` : null,
		createdAt: row.createdAt ? row.createdAt.toISOString() : null,
	};
}

function mapGuestTransfers(input: {
	transfers: Array<{
		fromMemberId: string;
		toMemberId: string;
		amount: number;
	}>;
	memberById: Map<string, MemberRow>;
	methods: PaymentMethodsMap;
	staticPurpose: string;
}) {
	return input.transfers.map((transfer) => {
		const from = input.memberById.get(transfer.fromMemberId);
		const to = input.memberById.get(transfer.toMemberId);
		if (!from || !to) throw new Error("Settlement member not found");
		const purpose = transferPurpose(from.name, to.name);
		return {
			fromMemberId: transfer.fromMemberId,
			toMemberId: transfer.toMemberId,
			amount: transfer.amount,
			purpose,
			payTo: buildPayToMethods({
				rows: input.methods.get(to.id) ?? [],
				amount: transfer.amount,
				purpose,
				staticPurpose: input.staticPurpose,
			}),
		};
	});
}

function mapGuestTransaction(input: {
	row: GuestTxRow;
	payers: TxAmountRow[];
	shares: TxAmountRow[];
	attachmentRows: AttachmentRow[];
}) {
	const { row } = input;
	return {
		id: row.id,
		type: row.type,
		description: row.description,
		amount: row.amount,
		currency: row.currency,
		occurredAt: row.occurredAt.toISOString(),
		category: TransactionCategory.nullable().parse(row.category),
		categoryId: row.categoryId,
		categoryName: row.categoryName ?? null,
		categoryColor: MemberColorCode.nullable().parse(row.categoryColor ?? null),
		payers: input.payers
			.filter((payer) => payer.transactionId === row.id)
			.map((payer) => ({ memberId: payer.memberId, amount: payer.amount })),
		shares: input.shares
			.filter((share) => share.transactionId === row.id)
			.map((share) => ({ memberId: share.memberId, amount: share.amount })),
		split: SplitInput.parse(row.split),
		paymentChannel: PaymentChannel.nullable().parse(row.paymentChannel ?? null),
		paymentNote: row.paymentNote ?? null,
		cycleId: row.cycleId ?? null,
		attachments:
			row.type === "transfer"
				? []
				: input.attachmentRows
						.filter(
							(attachment) =>
								attachment.transactionId === row.id &&
								attachment.purpose === "expense",
						)
						.slice(0, 3)
						.map(toAttachmentDto),
	};
}

export async function getGuestLink(deps: AppDeps, groupId: string) {
	const row = await readGroupGuestLink(deps.db, groupId);
	if (row === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	return GuestLinkResponse.parse({
		guestLink: toGuestLinkDto(deps.config.webOrigin, row),
	});
}

export async function enableOrRotateGuestLink(
	deps: AppDeps,
	input: { groupId: string; userId: string; rotate?: boolean },
) {
	let changed = false;
	const result = await deps.db.transaction(async (executor) => {
		const locked = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		assertGroupRowNotArchived(locked);
		const current = await readGroupGuestLink(executor, input.groupId);
		if (current === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		if (current.active && !input.rotate) {
			return GuestLinkResponse.parse({
				guestLink: toGuestLinkDto(deps.config.webOrigin, current),
			});
		}
		const now = deps.now();
		const token = randomBytes(32).toString("base64url");
		await updateGroupGuestLink(executor, {
			groupId: input.groupId,
			active: true,
			token,
			createdAt: now,
			now,
		});
		const action = current.active ? "guest_link.rotated" : "guest_link.enabled";
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action,
			entityType: "group",
			entityId: input.groupId,
			summary: action,
			after: { guestLinkActive: true },
			createdAt: now,
		});
		changed = true;
		return GuestLinkResponse.parse({
			guestLink: toGuestLinkDto(deps.config.webOrigin, {
				active: true,
				token,
				createdAt: now,
			}),
		});
	});
	if (changed) {
		deps.events.publishChanged(input.groupId, ["group", "activity"]);
	}
	return result;
}

export async function revokeGuestLink(
	deps: AppDeps,
	input: { groupId: string; userId: string },
) {
	let changed = false;
	const result = await deps.db.transaction(async (executor) => {
		const locked = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		if (locked === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const current = await readGroupGuestLink(executor, input.groupId);
		if (current === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const now = deps.now();
		if (current.active) {
			await updateGroupGuestLink(executor, {
				groupId: input.groupId,
				active: false,
				token: null,
				createdAt: null,
				now,
			});
			await insertActivity(executor, {
				groupId: input.groupId,
				actorUserId: input.userId,
				action: "guest_link.revoked",
				entityType: "group",
				entityId: input.groupId,
				summary: "guest_link.revoked",
				after: { guestLinkActive: false },
				createdAt: now,
			});
			changed = true;
		}
		return GuestLinkResponse.parse({
			guestLink: { active: false, url: null, createdAt: null },
		});
	});
	if (changed) {
		deps.events.publishChanged(input.groupId, ["group", "activity"]);
	}
	return result;
}

export async function getGuestGroupView(
	deps: AppDeps,
	input: { token: string; query: GuestGroupViewQuery },
) {
	const parsedToken = GuestToken.safeParse(input.token);
	if (!parsedToken.success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const cursor = decodeTransactionCursor(input.query.cursor);
	return deps.db.transaction(
		async (executor) => {
			const group = await findGroupByGuestToken(executor, parsedToken.data);
			if (group === null) {
				throw new AppError(404, "NOT_FOUND", "Resource not found");
			}
			const [cyclesPayload, breakdownPayload] = await Promise.all([
				getSettlementCyclesIn(executor, group.id),
				computeMemberBreakdownsIn(executor, {
					groupId: group.id,
					cycleId: input.query.cycleId ?? "auto",
				}),
			]);
			const selectedCycleId =
				breakdownPayload.resolvedFocus.kind === "cycle" &&
				breakdownPayload.resolvedFocus.cycleId
					? breakdownPayload.resolvedFocus.cycleId
					: "current";

			const [members, methods, fund, settlements, txRows] = await Promise.all([
				listGroupMembers(executor, group.id),
				listPaymentMethodsByGroup(executor, group.id),
				fundCashAndContributions(executor, group.id),
				suggestGroupTransfers(executor, {
					groupId: group.id,
					minimizeDebts: group.minimizeDebts,
				}),
				listGuestTransactionRows(executor, {
					groupId: group.id,
					cycleFilter: selectedCycleId,
					cursor,
					limit: input.query.limit + 1,
				}),
			]);

			const memberById = new Map(members.map((member) => [member.id, member]));
			const peopleIds = new Set(
				members
					.filter((member) => member.kind === "person")
					.map((member) => member.id),
			);
			const page = txRows.slice(0, input.query.limit);
			const pageIds = page.map((row) => row.id);
			const nonTransferIds = page
				.filter((row) => row.type !== "transfer")
				.map((row) => row.id);
			const [payers, shares, attachmentRows] = await Promise.all([
				listTransactionPayers(executor, group.id, pageIds),
				listTransactionShares(executor, group.id, pageIds),
				listAttachmentsForTransactions(executor, group.id, nonTransferIds),
			]);
			const last = page.at(-1);

			return GuestGroupViewResponse.parse({
				group: {
					id: group.id,
					name: group.name,
					currency: group.currency,
					minimized: group.minimizeDebts,
					archivedAt: group.archivedAt?.toISOString() ?? null,
				},
				members: members.map((member) => ({
					id: member.id,
					name: member.name,
					kind: member.kind,
					active: member.active,
					shape: member.shape,
					color: member.color,
				})),
				cycles: cyclesPayload.cycles,
				selectedCycleId,
				currentPeriod: cyclesPayload.currentPeriod,
				balances: settlements.balances.filter((entry) =>
					peopleIds.has(entry.memberId),
				),
				transfers: mapGuestTransfers({
					transfers: settlements.transfers,
					memberById,
					methods,
					staticPurpose: groupTransferPurpose(group.name),
				}),
				fund,
				resolvedFocus: breakdownPayload.resolvedFocus,
				breakdowns: breakdownPayload.breakdowns,
				transactions: {
					items: page.map((row) =>
						mapGuestTransaction({ row, payers, shares, attachmentRows }),
					),
					nextCursor:
						txRows.length > input.query.limit && last
							? encodeTransactionCursor(last)
							: null,
				},
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function getGuestAttachmentContent(
	deps: AppDeps,
	input: { token: string; attachmentId: string },
): Promise<{ bytes: Uint8Array; contentType: string }> {
	const parsedToken = GuestToken.safeParse(input.token);
	const parsedId = z.uuid().safeParse(input.attachmentId);
	if (!parsedToken.success || !parsedId.success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const group = await findGroupByGuestToken(deps.db, parsedToken.data);
	if (group === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const row = await findGuestAttachment(deps.db, group.id, parsedId.data);
	if (row === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const bytes = await deps.fileStore.get(row.storageKey);
	if (bytes === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	return { bytes, contentType: row.contentType };
}
