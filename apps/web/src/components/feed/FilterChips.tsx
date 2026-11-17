"use client";
import type { CategoryDto, MemberDto } from "@songphang/contract";
import {
	hasActiveFilters,
	type TransactionFilters,
} from "../../lib/transactions";
import { vi } from "../../messages/vi";

const TYPE_LABELS = {
	expense: vi.expenseForm.typeExpense,
	transfer: vi.expenseForm.typeTransfer,
	income: vi.expenseForm.typeIncome,
} as const;

export function FilterChips({
	filters,
	members,
	categories,
	onChange,
	onClear,
}: {
	filters: TransactionFilters;
	members: MemberDto[];
	categories: CategoryDto[];
	onChange: (next: TransactionFilters) => void;
	onClear: () => void;
}) {
	if (!hasActiveFilters(filters)) return null;
	const chips: Array<{ key: string; label: string; remove: () => void }> = [];
	if (filters.q) {
		chips.push({
			key: "q",
			label: `“${filters.q}”`,
			remove: () => onChange({ ...filters, q: undefined }),
		});
	}
	if (filters.memberId) {
		const member = members.find((m) => m.id === filters.memberId);
		chips.push({
			key: "member",
			label: `${vi.filter.member}: ${member?.name ?? filters.memberId}`,
			remove: () => onChange({ ...filters, memberId: undefined }),
		});
	}
	if (filters.category) {
		chips.push({
			key: "category",
			label: `${vi.filter.category}: ${vi.expenseForm.categories[filters.category]}`,
			remove: () => onChange({ ...filters, category: undefined }),
		});
	}
	if (filters.categoryId) {
		const custom = categories.find((c) => c.id === filters.categoryId);
		chips.push({
			key: "categoryId",
			label: `${vi.filter.category}: ${custom?.name ?? filters.categoryId}`,
			remove: () => onChange({ ...filters, categoryId: undefined }),
		});
	}
	if (filters.uncategorized) {
		chips.push({
			key: "uncategorized",
			label: `${vi.filter.category}: ${vi.stats.uncategorised}`,
			remove: () => onChange({ ...filters, uncategorized: undefined }),
		});
	}
	if (filters.type) {
		chips.push({
			key: "type",
			label: `${vi.filter.type}: ${TYPE_LABELS[filters.type]}`,
			remove: () => onChange({ ...filters, type: undefined }),
		});
	}
	if (filters.spendingOnly) {
		chips.push({
			key: "spendingOnly",
			label: `${vi.filter.type}: ${vi.expenseForm.typeExpense} / ${vi.expenseForm.typeIncome}`,
			remove: () => onChange({ ...filters, spendingOnly: undefined }),
		});
	}
	if (filters.from || filters.to) {
		const dateText =
			filters.from && filters.to
				? `${filters.from} → ${filters.to}`
				: (filters.from ?? filters.to ?? "");
		chips.push({
			key: "dates",
			label: dateText,
			remove: () => onChange({ ...filters, from: undefined, to: undefined }),
		});
	}
	return (
		<div className="flex flex-wrap items-center gap-1.5">
			{chips.map((chip) => (
				<button
					key={chip.key}
					type="button"
					onClick={chip.remove}
					className="min-h-11 rounded-pill bg-surface px-3 text-xs font-bold text-ink"
				>
					{chip.label} ×
				</button>
			))}
			<button
				type="button"
				onClick={onClear}
				className="min-h-11 rounded-pill bg-sunken px-3 text-xs font-bold text-ink"
			>
				{vi.filter.clear}
			</button>
		</div>
	);
}
