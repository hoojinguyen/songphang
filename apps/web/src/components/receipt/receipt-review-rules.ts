import {
	CreateTransactionRequest,
	type ExtrasAllocation,
	type ItemsSplitExtra,
	type ItemsSplitItem,
	type PreviewItemsResponse,
	type ReceiptScanDto,
} from "@songphang/contract";

export function receiptMismatch(
	scan: ReceiptScanDto,
	computedAmount: number | undefined,
): { printedTotal: number; scanComputed: number } | null {
	const printedTotal = scan.reading?.total ?? null;
	if (
		!scan.flags.includes("TOTAL_MISMATCH") ||
		scan.flags.includes("NO_ITEMS") ||
		scan.computed === null ||
		printedTotal === null ||
		computedAmount === printedTotal
	) {
		return null;
	}
	return { printedTotal, scanComputed: scan.computed };
}

// Returns the create request only when every save condition holds; amounts come from the API preview.
export function buildReceiptRequest(input: {
	editor: {
		description: string;
		occurredOn: string;
		payerId: string | null;
		extrasAllocation: ExtrasAllocation;
	};
	itemsPayload: {
		items: ItemsSplitItem[];
		extras: ItemsSplitExtra[];
		extrasAllocation?: ExtrasAllocation | undefined;
	} | null;
	preview: PreviewItemsResponse | undefined;
	attachmentId: string;
}): CreateTransactionRequest | null {
	const { editor, itemsPayload, preview } = input;
	const amount = preview?.computedAmount;
	if (
		!itemsPayload ||
		!preview ||
		preview.issues.length > 0 ||
		(preview.shares?.length ?? 0) === 0 ||
		amount === undefined ||
		amount <= 0 ||
		editor.payerId === null ||
		editor.description.trim().length === 0 ||
		!/^\d{4}-\d{2}-\d{2}$/.test(editor.occurredOn)
	) {
		return null;
	}
	const parsed = CreateTransactionRequest.safeParse({
		type: "expense",
		description: editor.description.trim(),
		amount,
		occurredAt: new Date(`${editor.occurredOn}T12:00:00+07:00`).toISOString(),
		category: null,
		categoryId: null,
		payers: [{ memberId: editor.payerId, amount }],
		split: {
			method: "items",
			items: itemsPayload.items,
			extras: itemsPayload.extras,
			...(itemsPayload.extras.length > 0
				? { extrasAllocation: editor.extrasAllocation }
				: {}),
		},
		attachmentIds: [input.attachmentId],
	});
	return parsed.success ? parsed.data : null;
}
