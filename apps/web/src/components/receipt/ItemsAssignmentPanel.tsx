"use client";
import {
	type ItemsSplitExtra,
	type ItemsSplitItem,
	type MemberDto,
	PreviewItemsRequest,
	type PreviewItemsResponse,
} from "@songphang/contract";
import { formatAmount, parseAmountInput } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { type EditableReceiptExtra, ExtrasFields } from "./ExtrasFields";
import { type EditableReceiptItem, ItemRow } from "./ItemRow";

export const MAX_ITEM_MEMBERS = 20;

export function toItemsPayload(
	items: EditableReceiptItem[],
	extras: EditableReceiptExtra[],
): { items: ItemsSplitItem[]; extras: ItemsSplitExtra[] } | null {
	if (items.length === 0 || items.length > 60 || extras.length > 6) {
		return null;
	}
	const builtItems: ItemsSplitItem[] = [];
	for (const item of items) {
		const name = item.name.trim();
		const amount = parseAmountInput(item.amountText);
		if (!name || amount === null || item.memberIds.length > MAX_ITEM_MEMBERS) {
			return null;
		}
		builtItems.push({ name, amount, memberIds: item.memberIds });
	}
	const builtExtras: ItemsSplitExtra[] = [];
	for (const extra of extras) {
		const amount = parseAmountInput(extra.amountText);
		if (amount === null) return null;
		builtExtras.push({
			kind: extra.kind,
			label: extra.label.trim(),
			amount,
		});
	}
	const checked = PreviewItemsRequest.safeParse({
		items: builtItems,
		extras: builtExtras,
	});
	return checked.success ? checked.data : null;
}

export function ItemsAssignmentPanel({
	items,
	extras,
	selectedItemId,
	activePeople,
	previewData,
	previewCurrent,
	previewError,
	onSelectItem,
	onChangeItem,
	onRemoveItem,
	onAddItem,
	onToggleMemberOnSelected,
	onSplitRemainingEqual,
	onAddExtra,
	onChangeExtra,
	onRemoveExtra,
}: {
	items: EditableReceiptItem[];
	extras: EditableReceiptExtra[];
	selectedItemId: string;
	activePeople: MemberDto[];
	previewData: PreviewItemsResponse | undefined;
	previewCurrent: boolean;
	previewError: boolean;
	onSelectItem: (id: string) => void;
	onChangeItem: (
		id: string,
		patch: Partial<Pick<EditableReceiptItem, "name" | "amountText">>,
	) => void;
	onRemoveItem: (id: string) => void;
	onAddItem: () => void;
	onToggleMemberOnSelected: (memberId: string) => void;
	onSplitRemainingEqual: () => void;
	onAddExtra: () => void;
	onChangeExtra: (
		id: string,
		patch: Partial<Pick<EditableReceiptExtra, "kind" | "label" | "amountText">>,
	) => void;
	onRemoveExtra: (id: string) => void;
}) {
	const selectedItem =
		items.find((item) => item.id === selectedItemId) ?? items[0];
	const unassignedCount = items.filter(
		(item) => item.memberIds.length === 0,
	).length;
	const hasInvalidTotal =
		previewCurrent &&
		previewData?.issues.some((issue) => issue.code === "INVALID_TOTAL");
	const hasUnassignedIssue =
		unassignedCount > 0 ||
		(previewCurrent &&
			previewData?.issues.some((issue) => issue.code === "ITEM_UNASSIGNED"));

	const selectedMemberCount = selectedItem?.memberIds.length ?? 0;
	const itemMembersFull = selectedMemberCount >= MAX_ITEM_MEMBERS;
	const groupExceedsItemCap = activePeople.length > MAX_ITEM_MEMBERS;

	return (
		<div className="grid gap-3">
			<div className="flex items-center justify-between gap-2">
				<button
					type="button"
					disabled={
						unassignedCount === 0 ||
						activePeople.length === 0 ||
						groupExceedsItemCap
					}
					onClick={onSplitRemainingEqual}
					className="min-h-11 rounded-pill bg-phrase-split px-4 text-xs font-extrabold text-ink disabled:opacity-40"
				>
					{vi.receipts.splitRemainingEqual}
				</button>
				<button
					type="button"
					disabled={items.length >= 60}
					onClick={onAddItem}
					className="min-h-11 rounded-pill bg-surface px-4 text-xs font-extrabold text-ink disabled:opacity-40"
				>
					+ {vi.receipts.addItem}
				</button>
			</div>

			<div className="grid gap-2">
				{items.map((item) => (
					<ItemRow
						key={item.id}
						item={item}
						selected={selectedItem?.id === item.id}
						members={activePeople}
						canRemove={items.length > 1}
						onSelect={() => onSelectItem(item.id)}
						onChange={(patch) => onChangeItem(item.id, patch)}
						onRemove={() => onRemoveItem(item.id)}
					/>
				))}
			</div>

			<ExtrasFields
				extras={extras}
				onAdd={onAddExtra}
				onChange={onChangeExtra}
				onRemove={onRemoveExtra}
			/>

			<section className="grid gap-2 rounded-[26px] bg-surface p-3">
				<div className="grid grid-cols-4 gap-2">
					{activePeople.map((member) => {
						const assigned = Boolean(
							selectedItem?.memberIds.includes(member.id),
						);
						const share = previewCurrent
							? previewData?.shares?.find((s) => s.memberId === member.id)
									?.amount
							: undefined;
						return (
							<button
								key={member.id}
								type="button"
								aria-pressed={assigned}
								disabled={!assigned && itemMembersFull}
								onClick={() => onToggleMemberOnSelected(member.id)}
								className={`flex min-h-[76px] flex-col items-center justify-center gap-1 rounded-[20px] p-2 text-xs font-bold transition-colors disabled:opacity-40 ${
									assigned ? "bg-sunken ring-2 ring-ink" : "bg-bg opacity-70"
								}`}
							>
								<MemberShape {...member} size={32} />
								<span className="max-w-full truncate text-ink">
									{member.name}
								</span>
								<span className="text-[11px] font-extrabold text-muted">
									{share !== undefined
										? formatAmount(share)
										: vi.common.pendingValue}
								</span>
							</button>
						);
					})}
				</div>
				{(groupExceedsItemCap || itemMembersFull) && (
					<p role="status" className="text-xs font-extrabold text-muted">
						{vi.receipts.maxItemMembers}
					</p>
				)}
				{previewError && (
					<p role="alert" className="text-xs font-bold text-ink">
						{vi.common.loadError}
					</p>
				)}
				{hasUnassignedIssue && (
					<p role="status" className="text-xs font-extrabold text-muted">
						{t(vi.receipts.saveBlocked, {
							count: String(Math.max(unassignedCount, 1)),
						})}
					</p>
				)}
				{!hasUnassignedIssue && hasInvalidTotal && (
					<p role="status" className="text-xs font-extrabold text-muted">
						{vi.receipts.invalidTotal}
					</p>
				)}
			</section>
		</div>
	);
}
