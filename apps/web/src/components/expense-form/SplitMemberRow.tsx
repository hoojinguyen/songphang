import type { MemberDto } from "@songphang/contract";
import { formatAmount, parseAmountInput } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";
import type { SplitMethod } from "./use-split-state";
export function SplitMemberRow({
	member,
	method,
	value,
	onChange,
	onRemove,
}: {
	member: MemberDto;
	method: SplitMethod;
	value: string;
	onChange: (value: string) => void;
	onRemove: () => void;
}) {
	return (
		<div className="flex min-w-0 items-center gap-2 rounded-[26px] border-[3px] border-transparent bg-surface p-3 focus-within:border-ink">
			<MemberShape {...member} size={32} />
			<span className="min-w-0 flex-1 break-words text-base font-extrabold">
				{member.name}
			</span>
			{method !== "equal" && (
				<label className="flex h-12 w-32 min-w-0 items-center gap-1 rounded-[18px] bg-bg px-2">
					<input
						aria-label={t(vi.split.memberField, { name: member.name })}
						inputMode={method === "exact" ? "numeric" : "decimal"}
						value={value}
						onChange={(event) => {
							const text = event.target.value;
							if (method === "exact") {
								const number = parseAmountInput(text);
								if (number !== null || !text)
									onChange(number === null ? "" : formatAmount(number));
							} else {
								const normalized = text.replace(",", ".");
								if (
									(method === "percent"
										? /^\d{0,3}(\.\d{0,2})?$/
										: /^\d{0,4}(\.\d{0,2})?$/
									).test(normalized)
								)
									onChange(normalized);
							}
						}}
						className="min-w-0 flex-1 bg-transparent text-right text-xl font-black"
					/>
					<span className="text-[10px] text-muted">
						{method === "exact"
							? vi.split.unitMoney
							: method === "shares"
								? vi.split.unitShares
								: vi.split.unitPercent}
					</span>
				</label>
			)}
			<OnlineButton
				type="button"
				aria-label={t(vi.split.removeMember, { name: member.name })}
				onClick={onRemove}
				className="flex size-11 shrink-0 items-center justify-center rounded-pill bg-bg"
			>
				<Icon name="close" size={18} />
			</OnlineButton>
		</div>
	);
}
