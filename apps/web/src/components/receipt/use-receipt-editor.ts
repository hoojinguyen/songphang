"use client";
import type { MemberDto, ReceiptScanDto } from "@songphang/contract";
import { toVietnamDate } from "@songphang/core";
import { useEffect, useState } from "react";
import { vi } from "../../messages/vi";
import type { EditableReceiptExtra } from "./ExtrasFields";
import type { EditableReceiptItem } from "./ItemRow";
import { MAX_ITEM_MEMBERS } from "./ItemsAssignmentPanel";

const MAX_ITEMS = 60;
const MAX_EXTRAS = 6;

function todayVietnamDate(): string {
	return toVietnamDate(new Date());
}

function initialItems(scan: ReceiptScanDto, merchant: string) {
	const reading = scan.reading;
	if (reading && reading.items.length > 0) {
		return reading.items.map(
			(item): EditableReceiptItem => ({
				id: crypto.randomUUID(),
				name: item.name,
				amountText: String(item.amount),
				memberIds: [],
			}),
		);
	}
	return [
		{
			id: crypto.randomUUID(),
			name: merchant,
			amountText:
				reading?.total !== null && reading?.total !== undefined
					? String(reading.total)
					: "0",
			memberIds: [],
		},
	];
}

function initialExtras(scan: ReceiptScanDto): EditableReceiptExtra[] {
	const reading = scan.reading;
	if (!reading || reading.items.length === 0) return [];
	return reading.extras.map((extra) => ({
		id: crypto.randomUUID(),
		kind: extra.kind,
		label: extra.label,
		amountText: String(extra.amount),
	}));
}

export function useReceiptEditor(input: {
	scan: ReceiptScanDto | undefined;
	myMemberId: string | null;
	payerOptions: MemberDto[];
	activePeople: MemberDto[];
}) {
	const { scan, myMemberId, payerOptions, activePeople } = input;
	const [initializedScanId, setInitializedScanId] = useState<string | null>(
		null,
	);
	const [description, setDescription] = useState<string>(vi.receipts.title);
	const [occurredOn, setOccurredOn] = useState<string>(todayVietnamDate);
	const [items, setItems] = useState<EditableReceiptItem[]>([]);
	const [extras, setExtras] = useState<EditableReceiptExtra[]>([]);
	const [selectedItemId, setSelectedItemId] = useState("");
	const [payerId, setPayerId] = useState<string | null>(null);
	const [mismatchDismissed, setMismatchDismissed] = useState(false);

	useEffect(() => {
		if (scan?.status !== "done" || initializedScanId === scan.id) return;
		const merchant = scan.reading?.merchant?.trim() || vi.receipts.title;
		const nextItems = initialItems(scan, merchant);
		setDescription(merchant);
		setOccurredOn(scan.reading?.occurredOn ?? todayVietnamDate());
		setItems(nextItems);
		setExtras(initialExtras(scan));
		setSelectedItemId(nextItems[0]?.id ?? "");
		setPayerId(
			payerOptions.find((m) => m.id === myMemberId)?.id ??
				payerOptions[0]?.id ??
				null,
		);
		setMismatchDismissed(false);
		setInitializedScanId(scan.id);
	}, [scan, initializedScanId, myMemberId, payerOptions]);

	const panelHandlers = {
		onSelectItem: setSelectedItemId,
		onChangeItem: (id: string, patch: Partial<EditableReceiptItem>) => {
			setItems((current) =>
				current.map((item) => (item.id === id ? { ...item, ...patch } : item)),
			);
		},
		onRemoveItem: (id: string) => {
			setItems((current) => {
				if (current.length <= 1) return current;
				const next = current.filter((item) => item.id !== id);
				if (selectedItemId === id) setSelectedItemId(next[0]?.id ?? "");
				return next;
			});
		},
		onAddItem: () => {
			if (items.length >= MAX_ITEMS) return;
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
					if (!exists && item.memberIds.length >= MAX_ITEM_MEMBERS) return item;
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
			const allIds = activePeople.map((m) => m.id);
			if (allIds.length === 0 || allIds.length > MAX_ITEM_MEMBERS) return;
			setItems((current) =>
				current.map((item) =>
					item.memberIds.length === 0 ? { ...item, memberIds: allIds } : item,
				),
			);
		},
		onAddExtra: () => {
			if (extras.length >= MAX_EXTRAS) return;
			setExtras((current) => [
				...current,
				{ id: crypto.randomUUID(), kind: "other", label: "", amountText: "0" },
			]);
		},
		onChangeExtra: (id: string, patch: Partial<EditableReceiptExtra>) => {
			setExtras((current) =>
				current.map((extra) =>
					extra.id === id ? { ...extra, ...patch } : extra,
				),
			);
		},
		onRemoveExtra: (id: string) => {
			setExtras((current) => current.filter((extra) => extra.id !== id));
		},
	};

	const addMismatchExtra = (adjustment: {
		kind: "other" | "discount";
		amount: number;
	}) => {
		if (extras.length >= MAX_EXTRAS) return;
		setExtras((current) => [
			...current,
			{
				id: crypto.randomUUID(),
				kind: adjustment.kind,
				label: vi.receipts.mismatchExtraLabel,
				amountText: String(adjustment.amount),
			},
		]);
	};

	return {
		ready: scan?.status === "done" && initializedScanId === scan.id,
		description,
		setDescription,
		occurredOn,
		setOccurredOn,
		items,
		extras,
		extrasFull: extras.length >= MAX_EXTRAS,
		selectedItemId,
		payerId,
		setPayerId,
		mismatchDismissed,
		dismissMismatch: () => setMismatchDismissed(true),
		addMismatchExtra,
		panelHandlers,
	};
}
