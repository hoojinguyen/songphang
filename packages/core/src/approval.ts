export function approvalStatusFor(input: {
	type: "expense" | "transfer" | "income";
	amount: number;
	threshold: number | null;
	actorIsOwner: boolean;
}): "none" | "pending" {
	if (
		input.type === "expense" &&
		input.threshold !== null &&
		input.amount >= input.threshold &&
		!input.actorIsOwner
	) {
		return "pending";
	}
	return "none";
}
