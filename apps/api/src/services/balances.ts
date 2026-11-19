import { BalancesResponse } from "@songphang/contract";
import { buildVietQrPayload, transferPurpose } from "@songphang/core";
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
					const payTo = (methods.get(to.id) ?? []).map((row) => {
						const method = paymentMethodDto(row);
						return method.kind === "bank"
							? {
									...method,
									qrPayload:
										transfer.amount <= MAX_VIETQR_AMOUNT
											? buildVietQrPayload({
													bankBin: method.bankBin,
													accountNumber: method.accountNumber,
													amount: transfer.amount,
													purpose,
												})
											: null,
								}
							: method;
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
								}
							: null,
					};
				}),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
