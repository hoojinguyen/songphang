import { vi } from "../../web/src/messages/vi.ts";

export const CSV_HEADERS = [
	vi.csv.date,
	vi.csv.type,
	vi.csv.description,
	vi.csv.category,
	vi.csv.totalAmount,
	vi.csv.payers,
] as const;

export const CSV_TYPE_LABELS: Record<string, string> = {
	expense: vi.csv.typeExpense,
	transfer: vi.csv.typeTransfer,
	income: vi.csv.typeIncome,
};

export const CSV_CATEGORY_LABELS: Record<string, string> =
	vi.expenseForm.categories;
