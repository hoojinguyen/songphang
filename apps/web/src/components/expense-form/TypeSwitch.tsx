import { vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
export type FormTransactionType = "expense" | "transfer" | "income";
export function TypeSwitch({
	value,
	onChange,
}: {
	value: FormTransactionType;
	onChange: (value: FormTransactionType) => void;
}) {
	return (
		<fieldset
			aria-label={vi.expenseForm.typeLabel}
			className="flex shrink-0 rounded-[22px] bg-surface p-1"
		>
			{(
				[
					["expense", vi.expenseForm.typeExpense],
					["transfer", vi.expenseForm.typeTransfer],
					["income", vi.expenseForm.typeIncome],
				] as const
			).map(([type, label]) => (
				<OnlineButton
					key={type}
					type="button"
					aria-pressed={value === type}
					onClick={() => onChange(type)}
					className={`min-h-11 min-w-11 rounded-[18px] px-2 text-xs font-bold ${value === type ? "bg-ink text-surface" : "text-ink"}`}
				>
					{label}
				</OnlineButton>
			))}
		</fieldset>
	);
}
