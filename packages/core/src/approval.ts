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

export function nextEditApprovalStatusFor(input: {
	type: "expense" | "transfer" | "income";
	amount: number;
	threshold: number | null;
	actorIsOwner: boolean;
}): "none" | "pending" | "approved" {
	if (input.type !== "expense") return "none";
	if (input.actorIsOwner) {
		return input.threshold !== null && input.amount >= input.threshold
			? "approved"
			: "none";
	}
	return approvalStatusFor(input);
}
