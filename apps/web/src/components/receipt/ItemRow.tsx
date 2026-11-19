"use client";
import type { MemberDto } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";

export type EditableReceiptItem = {
	id: string;
	name: string;
	amountText: string;
	memberIds: string[];
};

export function ItemRow({
	item,
	selected,
	members,
	canRemove,
	onSelect,
	onChange,
	onRemove,
}: {
	item: EditableReceiptItem;
	selected: boolean;
	members: MemberDto[];
	canRemove: boolean;
	onSelect: () => void;
	onChange: (
		next: Partial<Pick<EditableReceiptItem, "name" | "amountText">>,
	) => void;
	onRemove: () => void;
}) {
	const assigned = members.filter((m) => item.memberIds.includes(m.id));
	return (
		<div
			className={`min-h-[56px] rounded-[22px] bg-surface px-3 py-2 transition-colors ${
				selected ? "border-[3px] border-ink" : "border-[3px] border-transparent"
			}`}
		>
			<div className="flex items-center gap-2">
				<button
					type="button"
					aria-pressed={selected}
					aria-label={item.name.trim() || vi.receipts.itemNameLabel}
					onClick={onSelect}
					className="flex min-h-11 min-w-8 shrink-0 items-center justify-center rounded-pill px-2 text-xs font-extrabold text-muted hover:bg-sunken"
				>
					{selected ? "●" : "○"}
				</button>
				<input
					aria-label={vi.receipts.itemNameLabel}
					maxLength={80}
					value={item.name}
					onFocus={onSelect}
					onChange={(event) => onChange({ name: event.target.value })}
					placeholder={vi.receipts.itemNameLabel}
					className="min-h-11 min-w-0 flex-1 rounded-[14px] bg-transparent px-2 text-base font-extrabold text-ink focus:bg-sunken"
				/>
				<input
					aria-label={vi.receipts.itemAmountLabel}
					inputMode="numeric"
					value={item.amountText}
					onFocus={onSelect}
					onChange={(event) =>
						onChange({
							amountText: event.target.value.replace(/[^0-9]/g, ""),
						})
					}
					placeholder="0"
					className="min-h-11 w-28 shrink-0 rounded-[14px] bg-transparent px-2 text-right text-base font-bold text-ink focus:bg-sunken"
				/>
				{canRemove && (
					<button
						type="button"
						aria-label={vi.receipts.removeItem}
						onClick={onRemove}
						className="flex size-11 shrink-0 items-center justify-center rounded-pill text-muted hover:bg-sunken hover:text-ink"
					>
						<Icon name="trash" size={18} />
					</button>
				)}
			</div>
			<div className="mt-1 flex flex-wrap items-center gap-1.5 pl-10">
				{assigned.length > 0 ? (
					assigned.map((member) => (
						<MemberShape key={member.id} {...member} size={24} />
					))
				) : (
					<span className="text-xs text-muted">{vi.receipts.nobody}</span>
				)}
			</div>
		</div>
	);
}
