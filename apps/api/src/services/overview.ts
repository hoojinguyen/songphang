import {
	OverviewResponse,
	PersonalTransactionsQuery,
	PersonalTransactionsResponse,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroupAccess,
	listBalancesForGroups,
	listMembersForGroups,
	listOpenDisputeTransactionIds,
	listPendingApprovalsForGroups,
	listPendingSettlementsForGroups,
	listPersonalTransactionPayers,
	listPersonalTransactionRows,
	listPersonalTransactionShares,
	listUserGroups,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { collectPendingActions } from "./pending-actions.js";
import {
	buildSearchPattern,
	computeMyDelta,
	decodeTransactionCursor,
	encodeTransactionCursor,
} from "./transactions.js";

type UserGroupRow = Awaited<ReturnType<typeof listUserGroups>>[number];
type GroupMemberRow = Awaited<ReturnType<typeof listMembersForGroups>>[number];
type BalanceRow = Awaited<ReturnType<typeof listBalancesForGroups>>[number];
type PendingApprovalRow = Awaited<
	ReturnType<typeof listPendingApprovalsForGroups>
>[number];
type PersonalRow = Awaited<
	ReturnType<typeof listPersonalTransactionRows>
>[number];
type PersonalPayerRow = Awaited<
	ReturnType<typeof listPersonalTransactionPayers>
>[number];
type PersonalShareRow = Awaited<
	ReturnType<typeof listPersonalTransactionShares>
>[number];

async function hydrateApprovalActorNames(
	executor: DbExecutor,
	approvals: PendingApprovalRow[],
): Promise<PendingApprovalRow[]> {
	const missingIds = approvals
		.filter((row) => row.creatorName === null)
		.map((row) => row.id);
	if (missingIds.length === 0) return approvals;
	const payers = await listPersonalTransactionPayers(executor, missingIds);
	const firstPayerByTx = new Map<string, string>();
	for (const payer of payers) {
		if (!firstPayerByTx.has(payer.transactionId)) {
			firstPayerByTx.set(payer.transactionId, payer.memberName);
		}
	}
	return approvals.map((row) =>
		row.creatorName === null
			? { ...row, creatorName: firstPayerByTx.get(row.id) ?? "" }
			: row,
	);
}

function summarizeBalances(input: {
	groups: UserGroupRow[];
	members: GroupMemberRow[];
	balances: BalanceRow[];
}) {
	const balanceByMemberId = new Map(
		input.balances.map((row) => [row.memberId, row.balance]),
	);
	let totalOwedToMe = 0;
	let totalIOwe = 0;
	const groupBalances: Array<{
		groupId: string;
		groupName: string;
		archivedAt: string | null;
		role: UserGroupRow["role"];
		myBalance: number;
		memberCount: number;
		previewMembers: Array<{
			id: string;
			name: string;
			shape: GroupMemberRow["shape"];
			color: GroupMemberRow["color"];
		}>;
	}> = [];

	for (const group of input.groups) {
		const myBalance =
			group.memberId === null
				? 0
				: (balanceByMemberId.get(group.memberId) ?? 0);
		if (myBalance > 0) totalOwedToMe += myBalance;
		if (myBalance < 0) totalIOwe += -myBalance;
		if (myBalance === 0) continue;
		const people = input.members.filter(
			(member) => member.groupId === group.id && member.kind === "person",
		);
		groupBalances.push({
			groupId: group.id,
			groupName: group.name,
			archivedAt: group.archivedAt?.toISOString() ?? null,
			role: group.role,
			myBalance,
			memberCount: people.length,
			previewMembers: people.slice(0, 4).map((member) => ({
				id: member.id,
				name: member.name,
				shape: member.shape,
				color: member.color,
			})),
		});
	}

	groupBalances.sort((a, b) => {
		const absDiff = Math.abs(b.myBalance) - Math.abs(a.myBalance);
		if (absDiff !== 0) return absDiff;
		return a.groupName.localeCompare(b.groupName);
	});

	return {
		totalOwedToMe,
		totalIOwe,
		netBalance: totalOwedToMe - totalIOwe,
		groupBalances,
	};
}

export async function getMeOverview(deps: AppDeps, userId: string) {
	return deps.db.transaction(
		async (executor) => {
			const groups = await listUserGroups(executor, userId, "all");
			const groupIds = groups.map((group) => group.id);
			const activeGroupIds = groups
				.filter((group) => group.archivedAt === null)
				.map((group) => group.id);
			const [members, balances, pendingSettlements, rawPendingApprovals] =
				await Promise.all([
					listMembersForGroups(executor, groupIds),
					listBalancesForGroups(executor, groupIds),
					listPendingSettlementsForGroups(executor, activeGroupIds),
					listPendingApprovalsForGroups(executor, activeGroupIds),
				]);
			const pendingApprovals = await hydrateApprovalActorNames(
				executor,
				rawPendingApprovals,
			);
			const pending = collectPendingActions({
				groups,
				members,
				pendingSettlements,
				pendingApprovals,
			});
			const summary = summarizeBalances({ groups, members, balances });
			const archivedGroupCount = groups.filter(
				(group) => group.archivedAt !== null,
			).length;
			return OverviewResponse.parse({
				...summary,
				activeGroupCount: groups.length - archivedGroupCount,
				archivedGroupCount,
				pendingSettlementCount: pending.pendingSettlementCount,
				pendingApprovalCount: pending.pendingApprovalCount,
				pendingActions: pending.items.slice(0, 20).map((item) => ({
					...item,
					createdAt: item.createdAt.toISOString(),
				})),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

function summarizePayers(
	payers: PersonalPayerRow[],
	callerMemberId: string | null,
): string {
	const first = payers[0];
	if (first === undefined) return "";
	const callerIsPayer =
		callerMemberId !== null &&
		payers.some((payer) => payer.memberId === callerMemberId);
	const lead =
		payers.length === 1
			? first.memberId === callerMemberId
				? "Bạn"
				: first.memberName
			: callerIsPayer
				? "Bạn"
				: first.memberName;
	if (payers.length === 1) return lead;
	return `${lead} + ${payers.length - 1}`;
}

function toPersonalTransactionDto(input: {
	row: PersonalRow;
	payers: PersonalPayerRow[];
	shares: PersonalShareRow[];
	hasOpenDispute: boolean;
}) {
	const { row, payers, shares } = input;
	const participants = new Set([
		...payers.map((payer) => payer.memberId),
		...shares.map((share) => share.memberId),
	]);
	const myDelta =
		computeMyDelta({
			type: row.type,
			deletedAt: null,
			approvalStatus: row.approvalStatus,
			viewerMemberId: row.callerMemberId,
			payers,
			shares,
		}) ?? 0;
	return {
		id: row.id,
		groupId: row.groupId,
		groupName: row.groupName,
		groupArchivedAt: row.groupArchivedAt?.toISOString() ?? null,
		type: row.type,
		description: row.description,
		amount: row.amount,
		myDelta,
		occurredAt: row.occurredAt.toISOString(),
		category: row.category,
		categoryName: row.categoryName,
		payerSummary: summarizePayers(payers, row.callerMemberId),
		participantCount: participants.size,
		approvalStatus: row.approvalStatus,
		hasOpenDispute: input.hasOpenDispute,
	};
}

export async function listMeTransactions(
	deps: AppDeps,
	input: { userId: string; query: PersonalTransactionsQuery },
) {
	const query = PersonalTransactionsQuery.parse(input.query);
	const cursor = decodeTransactionCursor(query.cursor);
	const searchPattern = buildSearchPattern(query.q);
	return deps.db.transaction(
		async (executor) => {
			if (query.groupId !== undefined) {
				const access = await findGroupAccess(
					executor,
					query.groupId,
					input.userId,
				);
				if (access === null) {
					throw new AppError(404, "NOT_FOUND", "Resource not found");
				}
			}
			const rows = await listPersonalTransactionRows(executor, {
				userId: input.userId,
				limit: query.limit + 1,
				cursor,
				...(query.type === undefined ? {} : { type: query.type }),
				...(query.groupId === undefined ? {} : { groupId: query.groupId }),
				...(searchPattern === undefined ? {} : { searchPattern }),
			});
			const page = rows.slice(0, query.limit);
			const last = page.at(-1);
			const nextCursor =
				rows.length > query.limit && last !== undefined
					? encodeTransactionCursor(last)
					: null;
			if (page.length === 0) {
				return PersonalTransactionsResponse.parse({
					items: [],
					nextCursor: null,
				});
			}
			const ids = page.map((row) => row.id);
			const [payers, shares, openDisputes] = await Promise.all([
				listPersonalTransactionPayers(executor, ids),
				listPersonalTransactionShares(executor, ids),
				listOpenDisputeTransactionIds(executor, ids),
			]);
			return PersonalTransactionsResponse.parse({
				items: page.map((row) =>
					toPersonalTransactionDto({
						row,
						payers: payers.filter((payer) => payer.transactionId === row.id),
						shares: shares.filter((share) => share.transactionId === row.id),
						hasOpenDispute: openDisputes.has(row.id),
					}),
				),
				nextCursor,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
