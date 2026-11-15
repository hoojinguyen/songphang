import type { MemberDto } from "@songphang/contract";
import { formatAmount, formatMoney, parseAmountInput } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function PayerAmounts({
	members,
	values,
	amount,
	onChange,
}: {
	members: MemberDto[];
	values: Record<string, string>;
	amount: number;
	onChange: (id: string, value: string) => void;
}) {
	const total = members.reduce(
		(sum, member) => sum + (parseAmountInput(values[member.id] ?? "") ?? 0),
		0,
	);
	const difference = amount - total;
	return (
		<div className="grid gap-2">
			{members.map((member) => (
				<label
					key={member.id}
					className="flex min-w-0 items-center gap-2 rounded-[26px] border-[3px] border-transparent bg-surface p-3 focus-within:border-ink"
				>
					<MemberShape {...member} size={32} />
					<span className="min-w-0 flex-1 text-base font-extrabold">
						{member.name}
					</span>
					<input
						aria-label={t(vi.expenseForm.payerAmountLabel, {
							name: member.name,
						})}
						inputMode="numeric"
						value={values[member.id] ?? ""}
						onChange={(event) => {
							const parsed = parseAmountInput(event.target.value);
							if (parsed !== null || !event.target.value)
								onChange(
									member.id,
									parsed === null ? "" : formatAmount(parsed),
								);
						}}
						className="h-12 w-28 min-w-0 rounded-[18px] bg-bg px-3 text-right text-xl font-black"
					/>
				</label>
			))}
			<p
				role="status"
				className={`rounded-[22px] p-3 text-sm font-bold ${difference === 0 ? "bg-phrase-split" : "bg-debt-soft"}`}
			>
				{t(
					difference === 0
						? vi.expenseForm.payersMatch
						: difference > 0
							? vi.expenseForm.payersShort
							: vi.expenseForm.payersOver,
					{
						amount: formatMoney(
							difference === 0 ? amount : Math.abs(difference),
						),
					},
				)}
			</p>
		</div>
	);
}
