import { TransactionCategory } from "@songphang/contract";
import type { z } from "zod";
import { vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";

type Category = z.infer<typeof TransactionCategory>;
export function CategoryPicker({
	value,
	onChange,
}: {
	value: Category | null;
	onChange: (category: Category | null) => void;
}) {
	return (
		<fieldset
			aria-label={vi.expenseForm.categoryLabel}
			className="flex min-w-0 w-full shrink-0 gap-2 overflow-x-auto"
		>
			{TransactionCategory.options.map((category) => (
				<OnlineButton
					key={category}
					type="button"
					aria-pressed={value === category}
					onClick={() => onChange(value === category ? null : category)}
					className={`h-11 shrink-0 rounded-[22px] px-4 text-[13px] ${value === category ? "bg-ink text-surface" : "bg-surface"}`}
				>
					{vi.expenseForm.categories[category]}
				</OnlineButton>
			))}
		</fieldset>
	);
}
