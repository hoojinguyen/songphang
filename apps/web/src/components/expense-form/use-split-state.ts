"use client";
import { type MemberDto, SplitInput } from "@songphang/contract";
import { useState } from "react";
import { formatMoney, parseAmountInput } from "../../lib/money";
import { usePreviewItems } from "../../lib/receipt-scans";
import { t, vi } from "../../messages/vi";
import type { EditableReceiptExtra } from "../receipt/ExtrasFields";
import type { EditableReceiptItem } from "../receipt/ItemRow";
import { toItemsPayload } from "../receipt/ItemsAssignmentPanel";

export type SplitMethod = "equal" | "exact" | "shares" | "percent" | "items";
function hundredths(value: string): number | null {
	if (!/^\d{1,3}(\.\d{1,2})?$/.test(value)) return null;
	const [whole, fraction = ""] = value.split(".");
	return Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
}
function percentText(value: number): string {
	const digits = String(value).padStart(3, "0");
	return `${digits.slice(0, -2)}.${digits.slice(-2)}`.replace(/\.?0+$/, "");
}
export function useSplitState(
	members: MemberDto[],
	amount: number,
	initial?: SplitInput | null,
	groupId = "",
) {
	const [method, setMethod] = useState<SplitMethod>(initial?.method ?? "equal");
	const [ids, setIds] = useState<string[]>(() =>
		initial
			? initial.method === "equal" || initial.method === "exact"
				? [...initial.members]
				: initial.method === "items"
					? [...new Set(initial.items.flatMap((item) => item.memberIds))]
					: initial.entries.map((e) => e.memberId)
			: members.map((member) => member.id),
	);
	const [values, setValues] = useState<Record<string, string>>(() =>
		initial && initial.method !== "equal" && initial.method !== "items"
			? Object.fromEntries(
					initial.entries.map((e) => [
						e.memberId,
						"amount" in e
							? String(e.amount)
							: "weight" in e
								? e.weight
								: e.percent,
					]),
				)
			: {},
	);
	const [spread, setSpread] = useState(
		initial?.method === "exact" && initial.remainder === "equal_among_all",
	);
	const [items, setItems] = useState<EditableReceiptItem[]>(() =>
		initial?.method === "items"
			? initial.items.map((item) => ({
					id: crypto.randomUUID(),
					name: item.name,
					amountText: String(item.amount),
					memberIds: [...item.memberIds],
				}))
			: [
					{
						id: crypto.randomUUID(),
						name: vi.receipts.title,
						amountText: amount > 0 ? String(amount) : "0",
						memberIds: members.map((member) => member.id),
					},
				],
	);
	const [extras, setExtras] = useState<EditableReceiptExtra[]>(() =>
		initial?.method === "items"
			? initial.extras.map((extra) => ({
					id: crypto.randomUUID(),
					kind: extra.kind,
					label: extra.label,
					amountText: String(extra.amount),
				}))
			: [],
	);
	const [selectedItemId, setSelectedItemId] = useState(
		() => items[0]?.id ?? "",
	);

	const itemsPayload =
		method === "items" ? toItemsPayload(items, extras) : null;
	const itemsPreview = usePreviewItems(
		groupId,
		groupId && method === "items" ? itemsPayload : null,
	);
	const itemsComputedAmount = itemsPreview.current
		? itemsPreview.data?.computedAmount
		: undefined;
	const itemsValid =
		method === "items" &&
		Boolean(
			itemsPreview.current &&
				itemsPreview.data &&
				itemsPreview.data.issues.length === 0 &&
				(itemsPreview.data.shares?.length ?? 0) > 0 &&
				itemsPreview.data.computedAmount > 0,
		);

	const selected = members.filter((member) => ids.includes(member.id));
	const blank = selected.filter((member) => !values[member.id]);
	const total = selected.reduce(
		(sum, member) => sum + (parseAmountInput(values[member.id] ?? "") ?? 0),
		0,
	);
	const rest = amount - total;
	const sumPercent = selected.reduce(
		(sum, member) => sum + (hundredths(values[member.id] ?? "") ?? 0),
		0,
	);
	const matched =
		method === "equal" ||
		method === "shares" ||
		(method === "items" && itemsValid) ||
		(method === "exact" &&
			rest >= 0 &&
			(blank.length > 0 || spread || rest === 0)) ||
		(method === "percent" && sumPercent === 10000);
	const candidate =
		method === "equal"
			? { method, members: ids }
			: method === "items"
				? itemsPayload
					? {
							method: "items" as const,
							items: itemsPayload.items,
							extras: itemsPayload.extras,
						}
					: null
				: method === "exact"
					? {
							method,
							members: ids,
							entries: selected
								.filter((member) => values[member.id])
								.map((member) => ({
									memberId: member.id,
									amount: parseAmountInput(values[member.id] ?? ""),
								})),
							remainder:
								blank.length > 0
									? "equal_among_blank"
									: spread
										? "equal_among_all"
										: "none",
						}
					: {
							method,
							entries: selected.map((member) => ({
								memberId: member.id,
								...(method === "shares"
									? { weight: values[member.id] ?? member.defaultWeight }
									: { percent: values[member.id] ?? "" }),
							})),
						};
	const parsed = SplitInput.safeParse(candidate);
	const positiveWeight =
		method !== "shares" ||
		selected.some((member) =>
			/[1-9]/.test(values[member.id] ?? member.defaultWeight),
		);
	const split =
		parsed.success && matched && positiveWeight ? parsed.data : null;
	const effectiveAmount =
		method === "items" ? (itemsComputedAmount ?? 0) : amount;
	const text =
		method === "items"
			? itemsValid
				? t(vi.split.match, { amount: formatMoney(effectiveAmount) })
				: items.filter((item) => item.memberIds.length === 0).length > 0
					? t(vi.receipts.saveBlocked, {
							count: String(
								items.filter((item) => item.memberIds.length === 0).length,
							),
						})
					: vi.receipts.invalidTotal
			: method === "percent"
				? sumPercent === 10000
					? vi.split.percentMatch
					: t(
							sumPercent < 10000 ? vi.split.percentShort : vi.split.percentOver,
							{
								percent: percentText(Math.abs(10000 - sumPercent)),
							},
						)
				: method === "exact" && rest < 0
					? t(vi.split.over, { amount: formatMoney(-rest) })
					: method === "exact" && blank.length > 0
						? t(vi.split.blankShare, {
								amount: formatMoney(rest),
								count: String(blank.length),
							})
						: !split
							? t(vi.split.short, { amount: formatMoney(Math.max(0, rest)) })
							: t(vi.split.match, { amount: formatMoney(amount) });
	return {
		method,
		ids,
		selected,
		values,
		spread,
		rest,
		blankCount: blank.length,
		split,
		status: { text, matched: split !== null },
		setSpread,
		items,
		extras,
		selectedItemId,
		itemsPreview,
		itemsComputedAmount,
		setSelectedItemId,
		onChangeItem: (
			id: string,
			patch: Partial<Pick<EditableReceiptItem, "name" | "amountText">>,
		) =>
			setItems((current) =>
				current.map((item) => (item.id === id ? { ...item, ...patch } : item)),
			),
		onRemoveItem: (id: string) =>
			setItems((current) => {
				if (current.length <= 1) return current;
				const next = current.filter((item) => item.id !== id);
				if (selectedItemId === id) setSelectedItemId(next[0]?.id ?? "");
				return next;
			}),
		onAddItem: () => {
			if (items.length >= 60) return;
			const nextId = crypto.randomUUID();
			setItems((current) => [
				...current,
				{ id: nextId, name: "", amountText: "0", memberIds: [] },
			]);
			setSelectedItemId(nextId);
		},
		onToggleMemberOnSelected: (memberId: string) => {
			const targetId = selectedItemId || items[0]?.id;
			if (!targetId) return;
			setItems((current) =>
				current.map((item) => {
					if (item.id !== targetId) return item;
					const exists = item.memberIds.includes(memberId);
					return {
						...item,
						memberIds: exists
							? item.memberIds.filter((id) => id !== memberId)
							: [...item.memberIds, memberId],
					};
				}),
			);
		},
		onSplitRemainingEqual: () => {
			const allIds = members.map((m) => m.id);
			if (allIds.length === 0) return;
			setItems((current) =>
				current.map((item) =>
					item.memberIds.length === 0 ? { ...item, memberIds: allIds } : item,
				),
			);
		},
		onAddExtra: () => {
			if (extras.length >= 6) return;
			setExtras((current) => [
				...current,
				{ id: crypto.randomUUID(), kind: "other", label: "", amountText: "0" },
			]);
		},
		onChangeExtra: (
			id: string,
			patch: Partial<
				Pick<EditableReceiptExtra, "kind" | "label" | "amountText">
			>,
		) =>
			setExtras((current) =>
				current.map((extra) =>
					extra.id === id ? { ...extra, ...patch } : extra,
				),
			),
		onRemoveExtra: (id: string) =>
			setExtras((current) => current.filter((extra) => extra.id !== id)),
		changeMode: (next: SplitMethod) => {
			setMethod(next);
			setSpread(false);
			setValues(
				next === "shares"
					? Object.fromEntries(
							selected.map((member) => [member.id, member.defaultWeight]),
						)
					: {},
			);
		},
		setValue: (id: string, value: string) => {
			setValues((current) => ({ ...current, [id]: value }));
		},
		toggle: (id: string) => {
			setIds((current) =>
				current.includes(id)
					? current.filter((memberId) => memberId !== id)
					: members
							.filter(
								(member) => current.includes(member.id) || member.id === id,
							)
							.map((member) => member.id),
			);
			setValues((current) => {
				const next = { ...current };
				delete next[id];
				return next;
			});
		},
	};
}
