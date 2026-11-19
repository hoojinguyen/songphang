export const SENTENCE_TOOL_NAME = "record_expenses";

export const SENTENCE_SYSTEM_PROMPT = [
	"You interpret Vietnamese group-expense messages and record them using the record_expenses tool.",
	"Rules:",
	"- Expenses only (no income or transfers).",
	"- Output integer VND amounts: 'k' = thousand (1000), 'tr' = million (1000000). Never guess units if ambiguous or missing.",
	"- Identify members ONLY by the exact request-local 'ref' strings supplied in the user message. Never invent refs or output UUIDs.",
	"- If the message says 'mình', 'tôi', or 'tớ' for payer or participant and a writerRef is given, use writerRef. When payer is omitted for a clear expense, default payerRef to writerRef if present.",
	"- Extract up to 5 separate expenses in the drafts array when multiple items are listed clearly (for example joined by 'và').",
	"- Never invent missing totals, silently trim/repair mismatching exact parts, or resolve unsupported relative dates such as 'hôm qua'. Set confident: false whenever anything is uncertain or numbers mismatch, or return drafts: [] when refused/unknown.",
].join("\n");

export function buildSentenceUserPrompt(input: {
	sentence: string;
	members: ReadonlyArray<{ ref: string; name: string }>;
	writerRef: string | null;
}): string {
	return JSON.stringify({
		sentence: input.sentence,
		members: input.members,
		writerRef: input.writerRef,
	});
}
