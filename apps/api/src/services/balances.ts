import { BalancesResponse } from "@songphang/contract";
import {
	buildStaticVietQrPayload,
	buildVietQrPayload,
	groupTransferPurpose,
	transferPurpose,
} from "@songphang/core";
import {
	findGroup,
	fundCashAndContributions,
	listGroupMembers,
	listPaymentMethodsByGroup,
	listPendingSettlements,
	suggestGroupTransfers,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { paymentMethodDto } from "./payment-methods.js";

const MAX_VIETQR_AMOUNT = 999_999_999_999;

export function buildPayToMethods(input: {
	rows: ReadonlyArray<{
		kind: string;
		bankBin: string | null;
		accountNumber: string;
		accountName: string | null;
	}>;
	amount: number;
	purpose: string;
	staticPurpose: string;
}) {
	return input.rows.map((row) => {
		const method = paymentMethodDto(row);
		return method.kind === "bank"
			? {
					...method,
					qrPayload:
						input.amount <= MAX_VIETQR_AMOUNT
							? buildVietQrPayload({
									bankBin: method.bankBin,
									accountNumber: method.accountNumber,
									amount: input.amount,
									purpose: input.purpose,
								})
							: null,
					accountQrPayload: buildStaticVietQrPayload({
						bankBin: method.bankBin,
						accountNumber: method.accountNumber,
						purpose: input.staticPurpose,
					}),
				}
			: method;
	});
}

export async function getBalances(
	deps: AppDeps,
	groupId: string,
	userId: string,
) {
	return deps.db.transaction(
		async (executor) => {
			const group = await findGroup(executor, groupId);
			if (group === null)
				throw new AppError(404, "NOT_FOUND", "Resource not found");
			const { balances, transfers } = await suggestGroupTransfers(executor, {
				groupId,
				minimizeDebts: group.minimizeDebts,
			});
			if (balances.length === 0)
				return BalancesResponse.parse({
					currency: group.currency,
					minimized: group.minimizeDebts,
					balances: [],
					transfers: [],
					fund: null,
				});
			const [members, methods, pending, fund] = await Promise.all([
				listGroupMembers(executor, groupId),
				listPaymentMethodsByGroup(executor, groupId),
				listPendingSettlements(executor, groupId),
				fundCashAndContributions(executor, groupId),
			]);
			const peopleIds = new Set(
				members
					.filter((member) => member.kind === "person")
					.map((member) => member.id),
			);
			const peopleBalances = balances.filter((entry) =>
				peopleIds.has(entry.memberId),
			);
			const staticPurpose = groupTransferPurpose(group.name);
			return BalancesResponse.parse({
				currency: group.currency,
				minimized: group.minimizeDebts,
				balances: peopleBalances,
				fund,
				transfers: transfers.map((transfer) => {
					const from = members.find(
						(member) => member.id === transfer.fromMemberId,
					);
					const to = members.find(
						(member) => member.id === transfer.toMemberId,
					);
					if (!from || !to) throw new Error("Settlement member not found");
					const purpose = transferPurpose(from.name, to.name);
					const request = pending.find(
						(row) => row.fromMemberId === from.id && row.toMemberId === to.id,
					);
					const payTo = buildPayToMethods({
						rows: methods.get(to.id) ?? [],
						amount: transfer.amount,
						purpose,
						staticPurpose,
					});
					return {
						...transfer,
						purpose,
						payTo,
						pendingRequest: request
							? {
									id: request.id,
									amount: request.amount,
									createdByMe: request.createdBy === userId,
									channel: request.channel ?? null,
									note: request.note ?? null,
									proofAttachmentId: request.proofAttachmentId ?? null,
								}
							: null,
					};
				}),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
