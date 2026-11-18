export const RECEIPT_TOOL_NAME = "record_receipt";

export const RECEIPT_SYSTEM_PROMPT = [
	"You read Vietnamese point-of-sale receipts and output structured integer VND data using the record_receipt tool.",
	"Rules:",
	"- All amounts are non-negative integers in VND. Discounts use kind: 'discount' with a non-negative integer amount.",
	"- Never invent prices, items, merchants, dates, or totals that are not visibly printed; use null when merchant, occurredOn, or total is absent or illegible.",
	"- If the image is clearly not a receipt or bill, return merchant: null, occurredOn: null, items: [], extras: [], total: null.",
	"- Put taxes, VAT, service fees, delivery fees, and discounts in extras instead of items.",
	"- Preserve the printed final total when legible.",
].join("\n");

export const RECEIPT_USER_PROMPT =
	"Extract the receipt fields from this image and call record_receipt.";
