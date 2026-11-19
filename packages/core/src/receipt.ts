export type ReceiptCheckFlag = "TOTAL_MISMATCH" | "TOTAL_MISSING" | "NO_ITEMS";

export type ReceiptCheckInput = {
	items: ReadonlyArray<{ amount: number }>;
	extras: ReadonlyArray<{
		kind: "tax" | "service" | "discount" | "other";
		amount: number;
	}>;
	total: number | null;
};

export type ReceiptCheckResult =
	| { status: "done"; computed: number; flags: ReceiptCheckFlag[] }
	| { status: "failed"; errorCode: "NOT_A_RECEIPT" };

function assertSafeNonnegativeInt(value: number) {
	if (!Number.isSafeInteger(value) || value < 0) {
		throw new RangeError("Receipt amount must be a nonnegative safe integer");
	}
}

export function checkReceipt(reading: ReceiptCheckInput): ReceiptCheckResult {
	if (reading.items.length === 0 && reading.total === null) {
		return { status: "failed", errorCode: "NOT_A_RECEIPT" };
	}
	let itemsSum = 0;
	for (const item of reading.items) {
		assertSafeNonnegativeInt(item.amount);
		itemsSum += item.amount;
		if (!Number.isSafeInteger(itemsSum)) {
			throw new RangeError("Receipt computed total exceeds safe integer");
		}
	}
	let extrasNet = 0;
	for (const extra of reading.extras) {
		assertSafeNonnegativeInt(extra.amount);
		if (extra.kind === "discount") {
			extrasNet -= extra.amount;
		} else {
			extrasNet += extra.amount;
		}
		if (!Number.isSafeInteger(extrasNet)) {
			throw new RangeError("Receipt computed total exceeds safe integer");
		}
	}
	const computed = itemsSum + extrasNet;
	if (!Number.isSafeInteger(computed)) {
		throw new RangeError("Receipt computed total exceeds safe integer");
	}
	const flags: ReceiptCheckFlag[] = [];
	if (reading.items.length === 0) {
		flags.push("NO_ITEMS");
	}
	if (reading.total === null) {
		flags.push("TOTAL_MISSING");
	} else {
		assertSafeNonnegativeInt(reading.total);
		if (reading.total !== computed) {
			flags.push("TOTAL_MISMATCH");
		}
	}
	return { status: "done", computed, flags };
}

export type ReceiptAdjustment = { kind: "other" | "discount"; amount: number };

export function receiptAdjustment(
	printedTotal: number,
	computed: number,
): ReceiptAdjustment | null {
	assertSafeNonnegativeInt(printedTotal);
	if (!Number.isSafeInteger(computed)) {
		throw new RangeError("Receipt computed total must be a safe integer");
	}
	const difference = printedTotal - computed;
	if (difference === 0) return null;
	return {
		kind: difference > 0 ? "other" : "discount",
		amount: Math.abs(difference),
	};
}
