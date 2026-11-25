import {
	type MemberBreakdownLineDto,
	type MemberBreakdownsQuery,
	MemberBreakdownsResponse,
	MemberColorCode,
	MemberShapeCode,
} from "@songphang/contract";
import {
	type DbExecutor,
	listCountedTransactionsForBreakdown,
	listGroupLivePayers,
	listGroupLiveShares,
	listGroupMembers,
	listSettlementCycles,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";

function buildPayerSummary(input: {
	type: "expense" | "income" | "transfer";
	payers: Array<{ memberId: string; amount: number }>;
	shares: Array<{ memberId: string; amount: number }>;
	memberNameById: Map<string, string>;
}): string {
	const nameOf = (memberId: string) => input.memberNameById.get(memberId) ?? "";
	if (input.type === "transfer") {
		const fromName = nameOf(input.payers[0]?.memberId ?? "");
		const toName = nameOf(input.shares[0]?.memberId ?? "");
		return `${fromName} chuyển ${toName}`.trim();
	}
	const payerNames = input.payers.map((payer) => nameOf(payer.memberId));
	if (payerNames.length === 0) return "";
	if (payerNames.length === 1) return `${payerNames[0]} trả`;
	if (payerNames.length === 2) return `${payerNames[0]}, ${payerNames[1]} trả`;
	return `${payerNames[0]} +${payerNames.length - 1} trả`;
}

export async function computeMemberBreakdownsIn(
	executor: DbExecutor,
	input: {
		groupId: string;
		cycleId: MemberBreakdownsQuery["cycleId"];
	},
): Promise<MemberBreakdownsResponse> {
	const [cycles, members, txRows, payerRows, shareRows] = await Promise.all([
		listSettlementCycles(executor, input.groupId),
		listGroupMembers(executor, input.groupId),
		listCountedTransactionsForBreakdown(executor, input.groupId),
		listGroupLivePayers(executor, input.groupId),
		listGroupLiveShares(executor, input.groupId),
	]);

	const hasClosedCycles = cycles.length > 0;
	const cycleById = new Map(cycles.map((cycle) => [cycle.id, cycle]));
	const memberNameById = new Map(
		members.map((member) => [member.id, member.name]),
	);

	const payersByTx = new Map<
		string,
		Array<{ memberId: string; amount: number }>
	>();
	for (const payer of payerRows) {
		const list = payersByTx.get(payer.transactionId) ?? [];
		list.push({ memberId: payer.memberId, amount: payer.amount });
		payersByTx.set(payer.transactionId, list);
	}
	const sharesByTx = new Map<
		string,
		Array<{ memberId: string; amount: number }>
	>();
	for (const share of shareRows) {
		const list = sharesByTx.get(share.transactionId) ?? [];
		list.push({ memberId: share.memberId, amount: share.amount });
		sharesByTx.set(share.transactionId, list);
	}

	const openExpenseOrIncomeCount = txRows.filter(
		(row) =>
			row.cycleId === null && (row.type === "expense" || row.type === "income"),
	).length;

	let resolvedFocus: MemberBreakdownsResponse["resolvedFocus"];
	let focusMode: "all" | "current" | "latest_with_post_transfers" | "cycle";
	let targetCycleNumber = Number.POSITIVE_INFINITY;

	if (input.cycleId === "auto") {
		if (!hasClosedCycles) {
			resolvedFocus = { kind: "all", cycleId: null, label: "Đợt hiện tại" };
			focusMode = "all";
		} else if (openExpenseOrIncomeCount >= 1) {
			resolvedFocus = {
				kind: "current",
				cycleId: null,
				label: "Đợt hiện tại",
			};
			focusMode = "current";
		} else {
			const latestCycle = cycles[0];
			if (!latestCycle) {
				throw new Error("Expected latest cycle");
			}
			resolvedFocus = {
				kind: "cycle",
				cycleId: latestCycle.id,
				label: latestCycle.title,
			};
			focusMode = "latest_with_post_transfers";
			targetCycleNumber = latestCycle.cycleNumber;
		}
	} else if (input.cycleId === "current") {
		resolvedFocus = {
			kind: hasClosedCycles ? "current" : "all",
			cycleId: null,
			label: "Đợt hiện tại",
		};
		focusMode = "current";
	} else {
		const target = cycleById.get(input.cycleId);
		if (!target) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		resolvedFocus = {
			kind: "cycle",
			cycleId: target.id,
			label: target.title,
		};
		focusMode = "cycle";
		targetCycleNumber = target.cycleNumber;
	}

	const people = members.filter((member) => member.kind === "person");
	const breakdowns = people.map((member) => {
		let carryOverBalance = 0;
		let focusExpenseDelta = 0;
		let focusTransferDelta = 0;
		let postCycleDelta = 0;
		let netBalance = 0;
		const lines: MemberBreakdownLineDto[] = [];

		for (const tx of txRows) {
			if (
				tx.type !== "expense" &&
				tx.type !== "income" &&
				tx.type !== "transfer"
			) {
				throw new Error(`Unexpected transaction type: ${tx.type}`);
			}
			const txType = tx.type;
			const txPayers = payersByTx.get(tx.id) ?? [];
			const txShares = sharesByTx.get(tx.id) ?? [];

			let memberPaid = 0;
			for (const payer of txPayers) {
				if (payer.memberId === member.id) memberPaid += payer.amount;
			}
			let memberShare = 0;
			for (const share of txShares) {
				if (share.memberId === member.id) memberShare += share.amount;
			}
			const delta =
				txType === "income"
					? memberShare - memberPaid
					: memberPaid - memberShare;
			netBalance += delta;

			const txCycleNumber =
				tx.cycleId !== null
					? (cycleById.get(tx.cycleId)?.cycleNumber ?? null)
					: null;

			let bucket: "carry" | "focus" | "post" = "focus";
			let isPostCloseoutTransfer = false;

			if (focusMode === "all") {
				bucket = "focus";
			} else if (focusMode === "current") {
				bucket = tx.cycleId === null ? "focus" : "carry";
			} else if (focusMode === "latest_with_post_transfers") {
				if (tx.cycleId === resolvedFocus.cycleId) {
					bucket = "focus";
				} else if (tx.cycleId === null && txType === "transfer") {
					bucket = "focus";
					isPostCloseoutTransfer = true;
				} else if (
					txCycleNumber !== null &&
					txCycleNumber < targetCycleNumber
				) {
					bucket = "carry";
				} else {
					bucket = "post";
				}
			} else {
				if (tx.cycleId === resolvedFocus.cycleId) {
					bucket = "focus";
				} else if (
					txCycleNumber !== null &&
					txCycleNumber < targetCycleNumber
				) {
					bucket = "carry";
				} else {
					bucket = "post";
				}
			}

			if (bucket === "carry") {
				carryOverBalance += delta;
			} else if (bucket === "post") {
				postCycleDelta += delta;
			} else {
				if (txType === "transfer") {
					focusTransferDelta += delta;
				} else {
					focusExpenseDelta += delta;
				}
				if (delta !== 0) {
					lines.push({
						transactionId: tx.id,
						type: txType,
						description: tx.description,
						occurredAt: tx.occurredAt.toISOString(),
						totalAmount: tx.amount,
						payerSummary: buildPayerSummary({
							type: txType,
							payers: txPayers,
							shares: txShares,
							memberNameById,
						}),
						memberPaid,
						memberShare,
						delta,
						isPostCloseoutTransfer,
					});
				}
			}
		}

		return {
			memberId: member.id,
			memberName: member.name,
			shape: MemberShapeCode.parse(member.shape),
			color: MemberColorCode.parse(member.color),
			carryOverBalance,
			focusExpenseDelta,
			focusTransferDelta,
			postCycleDelta,
			netBalance,
			lines,
		};
	});

	return MemberBreakdownsResponse.parse({
		hasClosedCycles,
		resolvedFocus,
		breakdowns,
	});
}

export async function getMemberBreakdowns(
	deps: AppDeps,
	input: {
		groupId: string;
		cycleId: MemberBreakdownsQuery["cycleId"];
	},
) {
	return deps.db.transaction(
		(executor) => computeMemberBreakdownsIn(executor, input),
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
