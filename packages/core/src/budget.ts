export const BUDGET_NEAR_PERCENT = 80;

export type BudgetState = "ok" | "near" | "over";

export function budgetState(spent: number, amount: number): BudgetState {
	if (
		!Number.isSafeInteger(spent) ||
		!Number.isSafeInteger(amount) ||
		amount <= 0
	) {
		throw new RangeError("Spent must be a safe integer and amount > 0");
	}
	if (spent > amount) return "over";
	if (BigInt(spent) * 100n >= BigInt(amount) * BigInt(BUDGET_NEAR_PERCENT))
		return "near";
	return "ok";
}
