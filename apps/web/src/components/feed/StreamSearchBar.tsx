"use client";
import { useEffect, useState } from "react";
import { vi } from "../../messages/vi";

export function StreamSearchBar({
	value,
	onSearchChange,
	onOpenFilters,
	hasFilters,
}: {
	value: string;
	onSearchChange: (next: string) => void;
	onOpenFilters: () => void;
	hasFilters: boolean;
}) {
	const [draft, setDraft] = useState(value);
	useEffect(() => {
		setDraft(value);
	}, [value]);
	useEffect(() => {
		if (draft.trim() === value) return;
		const timer = setTimeout(() => {
			onSearchChange(draft.trim());
		}, 300);
		return () => clearTimeout(timer);
	}, [draft, value, onSearchChange]);

	return (
		<div className="flex items-center gap-2">
			<input
				type="search"
				value={draft}
				maxLength={100}
				aria-label={vi.filter.searchPlaceholder}
				placeholder={vi.filter.searchPlaceholder}
				onChange={(event) => setDraft(event.target.value)}
				className="min-h-11 min-w-0 flex-1 rounded-pill bg-surface px-4 text-sm font-semibold text-ink placeholder:text-muted"
			/>
			<button
				type="button"
				aria-haspopup="dialog"
				onClick={onOpenFilters}
				className={`min-h-11 shrink-0 rounded-pill px-4 text-xs font-bold ${
					hasFilters ? "bg-ink text-surface" : "bg-surface text-ink"
				}`}
			>
				{vi.filter.button}
			</button>
		</div>
	);
}
