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
	listGroupHouseholds,
	listGroupLivePayers,
	listGroupLiveShares,
	listGroupMembers,
	listSettlementCycles,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";

type TxType = "expense" | "income" | "transfer";
type MemberAmount = { memberId: string; amount: number };
type FocusMode = "all" | "current" | "latest_with_post_transfers" | "cycle";
type FocusResolution = {
	resolvedFocus: MemberBreakdownsResponse["resolvedFocus"];
	focusMode: FocusMode;
	targetCycleNumber: number;
};

type CycleRow = Awaited<ReturnType<typeof listSettlementCycles>>[number];
type TxRow = Awaited<
	ReturnType<typeof listCountedTransactionsForBreakdown>
>[number];
type MemberRow = Awaited<ReturnType<typeof listGroupMembers>>[number];

function buildPayerSummary(input: {
	type: TxType;
	payers: MemberAmount[];
	shares: MemberAmount[];
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

function groupAmountsByTransaction(
	rows: ReadonlyArray<{
		transactionId: string;
		memberId: string;
		amount: number;
	}>,
): Map<string, MemberAmount[]> {
	const grouped = new Map<string, MemberAmount[]>();
	for (const row of rows) {
		const list = grouped.get(row.transactionId) ?? [];
		list.push({ memberId: row.memberId, amount: row.amount });
		grouped.set(row.transactionId, list);
	}
	return grouped;
}

function sumMemberAmount(entries: MemberAmount[], memberId: string): number {
	let total = 0;
	for (const entry of entries) {
		if (entry.memberId === memberId) total += entry.amount;
	}
	return total;
}

function parseTxType(type: string): TxType {
	if (type !== "expense" && type !== "income" && type !== "transfer") {
		throw new Error(`Unexpected transaction type: ${type}`);
	}
	return type;
}

function resolveBreakdownFocus(input: {
	cycleId: MemberBreakdownsQuery["cycleId"];
	cycles: CycleRow[];
	cycleById: Map<string, CycleRow>;
	openExpenseOrIncomeCount: number;
}): FocusResolution {
	const hasClosedCycles = input.cycles.length > 0;
	if (input.cycleId === "auto") {
		if (!hasClosedCycles) {
			return {
				resolvedFocus: { kind: "all", cycleId: null, label: "Đợt hiện tại" },
				focusMode: "all",
				targetCycleNumber: Number.POSITIVE_INFINITY,
			};
		}
		if (input.openExpenseOrIncomeCount >= 1) {
			return {
				resolvedFocus: {
					kind: "current",
					cycleId: null,
					label: "Đợt hiện tại",
				},
				focusMode: "current",
				targetCycleNumber: Number.POSITIVE_INFINITY,
			};
		}
		const latestCycle = input.cycles[0];
		if (!latestCycle) {
			throw new Error("Expected latest cycle");
		}
		return {
			resolvedFocus: {
				kind: "cycle",
				cycleId: latestCycle.id,
				label: latestCycle.title,
			},
			focusMode: "latest_with_post_transfers",
			targetCycleNumber: latestCycle.cycleNumber,
		};
	}
	if (input.cycleId === "current") {
		return {
			resolvedFocus: {
				kind: hasClosedCycles ? "current" : "all",
				cycleId: null,
				label: "Đợt hiện tại",
			},
			focusMode: "current",
			targetCycleNumber: Number.POSITIVE_INFINITY,
		};
	}
	const target = input.cycleById.get(input.cycleId);
	if (!target) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	return {
		resolvedFocus: {
			kind: "cycle",
			cycleId: target.id,
			label: target.title,
		},
		focusMode: "cycle",
		targetCycleNumber: target.cycleNumber,
	};
}

function classifyTransactionBucket(input: {
	txCycleId: string | null;
	txType: TxType;
	txCycleNumber: number | null;
	focus: FocusResolution;
}): { bucket: "carry" | "focus" | "post"; isPostCloseoutTransfer: boolean } {
	const { focus } = input;
	if (focus.focusMode === "all") {
		return { bucket: "focus", isPostCloseoutTransfer: false };
	}
	if (focus.focusMode === "current") {
		return {
			bucket: input.txCycleId === null ? "focus" : "carry",
			isPostCloseoutTransfer: false,
		};
	}
	if (input.txCycleId === focus.resolvedFocus.cycleId) {
		return { bucket: "focus", isPostCloseoutTransfer: false };
	}
	if (
		focus.focusMode === "latest_with_post_transfers" &&
		input.txCycleId === null &&
		input.txType === "transfer"
	) {
		return { bucket: "focus", isPostCloseoutTransfer: true };
	}
	if (
		input.txCycleNumber !== null &&
		input.txCycleNumber < focus.targetCycleNumber
	) {
		return { bucket: "carry", isPostCloseoutTransfer: false };
	}
	return { bucket: "post", isPostCloseoutTransfer: false };
}

function buildMemberBreakdown(input: {
	member: MemberRow;
	txRows: TxRow[];
	payersByTx: Map<string, MemberAmount[]>;
	sharesByTx: Map<string, MemberAmount[]>;
	cycleById: Map<string, CycleRow>;
	memberNameById: Map<string, string>;
	focus: FocusResolution;
}) {
	let carryOverBalance = 0;
	let focusExpenseDelta = 0;
	let focusTransferDelta = 0;
	let postCycleDelta = 0;
	let netBalance = 0;
	const lines: MemberBreakdownLineDto[] = [];

	for (const tx of input.txRows) {
		const txType = parseTxType(tx.type);
		const txPayers = input.payersByTx.get(tx.id) ?? [];
		const txShares = input.sharesByTx.get(tx.id) ?? [];
		const memberPaid = sumMemberAmount(txPayers, input.member.id);
		const memberShare = sumMemberAmount(txShares, input.member.id);
		const delta =
			txType === "income" ? memberShare - memberPaid : memberPaid - memberShare;
		netBalance += delta;

		const txCycleNumber =
			tx.cycleId !== null
				? (input.cycleById.get(tx.cycleId)?.cycleNumber ?? null)
				: null;
		const { bucket, isPostCloseoutTransfer } = classifyTransactionBucket({
			txCycleId: tx.cycleId,
			txType,
			txCycleNumber,
			focus: input.focus,
		});

		if (bucket === "carry") {
			carryOverBalance += delta;
			continue;
		}
		if (bucket === "post") {
			postCycleDelta += delta;
			continue;
		}
		if (txType === "transfer") {
			focusTransferDelta += delta;
		} else {
			focusExpenseDelta += delta;
		}
		if (delta === 0) continue;

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
				memberNameById: input.memberNameById,
			}),
			memberPaid,
			memberShare,
			delta,
			isPostCloseoutTransfer,
		});
	}

	return {
		memberId: input.member.id,
		memberName: input.member.name,
		shape: MemberShapeCode.parse(input.member.shape),
		color: MemberColorCode.parse(input.member.color),
		carryOverBalance,
		focusExpenseDelta,
		focusTransferDelta,
		postCycleDelta,
		netBalance,
		lines,
	};
}

function toSafeMoneyInt(value: bigint): number {
	if (
		value < BigInt(Number.MIN_SAFE_INTEGER) ||
		value > BigInt(Number.MAX_SAFE_INTEGER)
	) {
		throw new RangeError(
			"Household breakdown amount exceeds safe integer range",
		);
	}
	return Number(value);
}

export async function computeMemberBreakdownsIn(
	executor: DbExecutor,
	input: {
		groupId: string;
		cycleId: MemberBreakdownsQuery["cycleId"];
	},
): Promise<MemberBreakdownsResponse> {
	const [cycles, members, households, txRows, payerRows, shareRows] =
		await Promise.all([
			listSettlementCycles(executor, input.groupId),
			listGroupMembers(executor, input.groupId),
			listGroupHouseholds(executor, input.groupId),
			listCountedTransactionsForBreakdown(executor, input.groupId),
			listGroupLivePayers(executor, input.groupId),
			listGroupLiveShares(executor, input.groupId),
		]);

	const cycleById = new Map(cycles.map((cycle) => [cycle.id, cycle]));
	const memberNameById = new Map(
		members.map((member) => [member.id, member.name]),
	);
	const payersByTx = groupAmountsByTransaction(payerRows);
	const sharesByTx = groupAmountsByTransaction(shareRows);
	const openExpenseOrIncomeCount = txRows.filter(
		(row) =>
			row.cycleId === null && (row.type === "expense" || row.type === "income"),
	).length;
	const focus = resolveBreakdownFocus({
		cycleId: input.cycleId,
		cycles,
		cycleById,
		openExpenseOrIncomeCount,
	});
	const people = members.filter((member) => member.kind === "person");
	const breakdowns = people.map((member) =>
		buildMemberBreakdown({
			member,
			txRows,
			payersByTx,
			sharesByTx,
			cycleById,
			memberNameById,
			focus,
		}),
	);
	const breakdownByMemberId = new Map(
		breakdowns.map((entry) => [entry.memberId, entry]),
	);
	const householdBreakdowns = households.map((household) => {
		let carryOverBalance = 0n;
		let focusExpenseDelta = 0n;
		let focusTransferDelta = 0n;
		let postCycleDelta = 0n;
		let netBalance = 0n;
		for (const memberId of household.memberIds) {
			const entry = breakdownByMemberId.get(memberId);
			if (!entry) continue;
			carryOverBalance += BigInt(entry.carryOverBalance);
			focusExpenseDelta += BigInt(entry.focusExpenseDelta);
			focusTransferDelta += BigInt(entry.focusTransferDelta);
			postCycleDelta += BigInt(entry.postCycleDelta);
			netBalance += BigInt(entry.netBalance);
		}
		return {
			householdId: household.id,
			name: household.name,
			representativeMemberId: household.representativeMemberId,
			memberIds: household.memberIds,
			carryOverBalance: toSafeMoneyInt(carryOverBalance),
			focusExpenseDelta: toSafeMoneyInt(focusExpenseDelta),
			focusTransferDelta: toSafeMoneyInt(focusTransferDelta),
			postCycleDelta: toSafeMoneyInt(postCycleDelta),
			netBalance: toSafeMoneyInt(netBalance),
		};
	});

	return MemberBreakdownsResponse.parse({
		hasClosedCycles: cycles.length > 0,
		resolvedFocus: focus.resolvedFocus,
		breakdowns,
		householdBreakdowns,
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
