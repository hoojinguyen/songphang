"use client";
import type { ExtrasAllocation, ItemsSplitExtra } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { SegmentedControl } from "../ui/SegmentedControl";

export type EditableReceiptExtra = {
	id: string;
	kind: ItemsSplitExtra["kind"];
	label: string;
	amountText: string;
};

const EXTRA_KINDS: ItemsSplitExtra["kind"][] = [
	"tax",
	"service",
	"shipping",
	"discount",
	"other",
];

export function ExtrasFields({
	extras,
	extrasAllocation,
	onChangeAllocation,
	onAdd,
	onChange,
	onRemove,
}: {
	extras: EditableReceiptExtra[];
	extrasAllocation?: ExtrasAllocation;
	onChangeAllocation?: (next: ExtrasAllocation) => void;
	onAdd: () => void;
	onChange: (
		id: string,
		patch: Partial<Pick<EditableReceiptExtra, "kind" | "label" | "amountText">>,
	) => void;
	onRemove: (id: string) => void;
}) {
	return (
		<section className="grid gap-2 rounded-[26px] bg-surface p-3">
			<div className="flex items-center justify-between gap-2">
				<p className="text-xs font-semibold text-muted">
					{vi.receipts.extrasHint}
				</p>
				<button
					type="button"
					disabled={extras.length >= 6}
					onClick={onAdd}
					className="min-h-11 shrink-0 rounded-pill bg-sunken px-3 text-xs font-extrabold text-ink disabled:opacity-40"
				>
					+ {vi.receipts.addExtra}
				</button>
			</div>
			{extras.length > 0 &&
				extrasAllocation !== undefined &&
				onChangeAllocation !== undefined && (
					<SegmentedControl
						label={vi.extras.cardTitle}
						allowOffline
						value={extrasAllocation}
						onChange={(value) => {
							if (value === "equal" || value === "proportional") {
								onChangeAllocation(value);
							}
						}}
						options={[
							{ value: "equal", label: vi.extras.allocEqual },
							{ value: "proportional", label: vi.extras.allocProportional },
						]}
					/>
				)}
			{extras.length >= 6 && (
				<p role="status" className="text-xs font-semibold text-muted">
					{vi.receipts.maxExtras}
				</p>
			)}
			{extras.map((extra) => (
				<div key={extra.id} className="flex items-center gap-2">
					<select
						aria-label={vi.receipts.extrasKinds[extra.kind]}
						value={extra.kind}
						onChange={(event) => {
							const kind = EXTRA_KINDS.find((k) => k === event.target.value);
							if (kind) onChange(extra.id, { kind });
						}}
						className="min-h-11 rounded-[16px] bg-sunken px-2 text-sm font-bold text-ink"
					>
						{EXTRA_KINDS.map((kind) => (
							<option key={kind} value={kind}>
								{vi.receipts.extrasKinds[kind]}
							</option>
						))}
					</select>
					<input
						aria-label={vi.receipts.extraLabelLabel}
						maxLength={40}
						value={extra.label}
						onChange={(event) =>
							onChange(extra.id, { label: event.target.value })
						}
						placeholder={vi.receipts.extrasKinds[extra.kind]}
						className="min-h-11 min-w-0 flex-1 rounded-[16px] bg-sunken px-3 text-base font-bold text-ink"
					/>
					<input
						aria-label={vi.receipts.extraAmountLabel}
						inputMode="numeric"
						value={extra.amountText}
						onChange={(event) =>
							onChange(extra.id, {
								amountText: event.target.value.replace(/[^0-9]/g, ""),
							})
						}
						placeholder="0"
						className="min-h-11 w-24 shrink-0 rounded-[16px] bg-sunken px-2 text-right text-base font-bold text-ink"
					/>
					<button
						type="button"
						aria-label={vi.receipts.removeExtra}
						onClick={() => onRemove(extra.id)}
						className="flex size-11 shrink-0 items-center justify-center rounded-pill text-muted hover:bg-sunken hover:text-ink"
					>
						<Icon name="trash" size={18} />
					</button>
				</div>
			))}
		</section>
	);
}
