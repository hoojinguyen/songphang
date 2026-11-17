"use client";
import {
	type CategoryDto,
	type MemberDto,
	TransactionCategory,
} from "@songphang/contract";
import { isWithinFiveYears } from "@songphang/core";
import { useEffect, useId, useRef, useState } from "react";
import type { TransactionFilters } from "../../lib/transactions";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";

const TYPES = [
	{ value: "expense", label: vi.expenseForm.typeExpense },
	{ value: "transfer", label: vi.expenseForm.typeTransfer },
	{ value: "income", label: vi.expenseForm.typeIncome },
] as const;

function PillSection<T extends string>({
	title,
	options,
	selected,
	onSelect,
}: {
	title: string;
	options: ReadonlyArray<{ value: T; label: string }>;
	selected: T | undefined;
	onSelect: (value: T | undefined) => void;
}) {
	return (
		<div className="grid gap-2">
			<span className="text-xs font-bold text-muted">{title}</span>
			<div className="flex flex-wrap gap-1.5">
				{options.map((option) => (
					<button
						key={option.value}
						type="button"
						aria-pressed={selected === option.value}
						onClick={() =>
							onSelect(selected === option.value ? undefined : option.value)
						}
						className={`min-h-11 rounded-pill px-3 text-xs font-bold ${
							selected === option.value
								? "bg-ink text-surface"
								: "bg-surface text-ink"
						}`}
					>
						{option.label}
					</button>
				))}
			</div>
		</div>
	);
}

export function FilterSheet({
	open,
	filters,
	members,
	categories,
	onApply,
	onClear,
	onClose,
}: {
	open: boolean;
	filters: TransactionFilters;
	members: MemberDto[];
	categories: CategoryDto[];
	onApply: (next: TransactionFilters) => void;
	onClear: () => void;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const [memberId, setMemberId] = useState(filters.memberId);
	const [category, setCategory] = useState(filters.category);
	const [categoryId, setCategoryId] = useState(filters.categoryId);
	const [uncategorized, setUncategorized] = useState(filters.uncategorized);
	const [type, setType] = useState(filters.type);
	const [from, setFrom] = useState(filters.from ?? "");
	const [to, setTo] = useState(filters.to ?? "");

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			setMemberId(filters.memberId);
			setCategory(filters.category);
			setCategoryId(filters.categoryId);
			setUncategorized(filters.uncategorized);
			setType(filters.type);
			setFrom(filters.from ?? "");
			setTo(filters.to ?? "");
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open, filters]);

	const invalidRange =
		Boolean(from) && Boolean(to) && !isWithinFiveYears(from, to);
	const categoryValue = category
		? `b:${category}`
		: categoryId
			? `c:${categoryId}`
			: uncategorized
				? "uncategorized"
				: undefined;
	const categoryOptions = [
		...TransactionCategory.options.map((code) => ({
			value: `b:${code}`,
			label: vi.expenseForm.categories[code],
		})),
		...categories.map((custom) => ({
			value: `c:${custom.id}`,
			label: custom.name,
		})),
		{ value: "uncategorized", label: vi.stats.uncategorised },
	];

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto w-[calc(100%-32px)] max-w-[398px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
		>
			<div className="grid gap-4">
				<h2 id={titleId} className="text-lg font-black">
					{vi.filter.button}
				</h2>
				<PillSection
					title={vi.filter.member}
					options={members.map((m) => ({ value: m.id, label: m.name }))}
					selected={memberId}
					onSelect={setMemberId}
				/>
				<PillSection
					title={vi.filter.category}
					options={categoryOptions}
					selected={categoryValue}
					onSelect={(val) => {
						if (!val) {
							setCategory(undefined);
							setCategoryId(undefined);
							setUncategorized(undefined);
						} else if (val === "uncategorized") {
							setCategory(undefined);
							setCategoryId(undefined);
							setUncategorized(true);
						} else if (val.startsWith("b:")) {
							const parsed = TransactionCategory.safeParse(val.slice(2));
							setCategory(parsed.success ? parsed.data : undefined);
							setCategoryId(undefined);
							setUncategorized(undefined);
						} else {
							setCategory(undefined);
							setCategoryId(val.slice(2));
							setUncategorized(undefined);
						}
					}}
				/>
				<PillSection
					title={vi.filter.type}
					options={TYPES}
					selected={type}
					onSelect={setType}
				/>
				<div className="grid grid-cols-2 gap-2">
					<label className="grid gap-1 text-xs font-bold text-muted">
						{vi.filter.fromDate}
						<input
							type="date"
							value={from}
							onChange={(event) => setFrom(event.target.value)}
							className="min-h-11 rounded-[20px] bg-surface px-3 text-sm font-bold text-ink"
						/>
					</label>
					<label className="grid gap-1 text-xs font-bold text-muted">
						{vi.filter.toDate}
						<input
							type="date"
							value={to}
							onChange={(event) => setTo(event.target.value)}
							className="min-h-11 rounded-[20px] bg-surface px-3 text-sm font-bold text-ink"
						/>
					</label>
				</div>
				<div className="flex gap-2 pt-2">
					<Button
						variant="surface"
						allowOffline
						className="flex-1"
						onClick={() => {
							onClear();
							onClose();
						}}
					>
						{vi.filter.clear}
					</Button>
					<Button
						variant="primary"
						allowOffline
						className="flex-1"
						disabled={invalidRange}
						onClick={() => {
							onApply({
								...(filters.q ? { q: filters.q } : {}),
								...(memberId ? { memberId } : {}),
								...(category ? { category } : {}),
								...(categoryId ? { categoryId } : {}),
								...(uncategorized ? { uncategorized } : {}),
								...(type ? { type } : {}),
								...(filters.spendingOnly && type === undefined
									? { spendingOnly: true }
									: {}),
								...(from ? { from } : {}),
								...(to ? { to } : {}),
							});
							onClose();
						}}
					>
						{vi.filter.apply}
					</Button>
				</div>
			</div>
		</dialog>
	);
}
