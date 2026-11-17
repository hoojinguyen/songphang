"use client";
import { type CategoryDto, TransactionCategory } from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import type { z } from "zod";
import { vi } from "../../messages/vi";
import { CategoryList } from "../settings/CategoryList";
import { CATEGORY_COLORS } from "../settings/CategoryRow";
import { Button } from "../ui/Button";
import { OnlineButton } from "../ui/OnlineButton";

type Category = z.infer<typeof TransactionCategory>;

export function CategoryPicker({
	groupId,
	categories,
	value,
	categoryId,
	onChange,
	onChangeCustom,
}: {
	groupId: string;
	categories: CategoryDto[];
	value: Category | null;
	categoryId: string | null;
	onChange: (category: Category | null) => void;
	onChangeCustom: (id: string | null) => void;
}) {
	const [manageOpen, setManageOpen] = useState(false);
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (manageOpen && !dialog.open) dialog.showModal();
		else if (!manageOpen && dialog.open) dialog.close();
	}, [manageOpen]);

	const visibleCustom = categories.filter(
		(custom) => !custom.archived || custom.id === categoryId,
	);

	return (
		<>
			<fieldset
				aria-label={vi.expenseForm.categoryLabel}
				className="flex min-w-0 w-full shrink-0 gap-2 overflow-x-auto"
			>
				{TransactionCategory.options.map((category) => (
					<OnlineButton
						key={category}
						type="button"
						aria-pressed={value === category}
						onClick={() => onChange(value === category ? null : category)}
						className={`h-11 shrink-0 rounded-[22px] px-4 text-[13px] ${value === category ? "bg-ink text-surface" : "bg-surface"}`}
					>
						{vi.expenseForm.categories[category]}
					</OnlineButton>
				))}
				{visibleCustom.map((custom) => {
					const selected = categoryId === custom.id;
					return (
						<OnlineButton
							key={custom.id}
							type="button"
							aria-pressed={selected}
							onClick={() => onChangeCustom(selected ? null : custom.id)}
							className={`flex h-11 shrink-0 items-center gap-2 rounded-[22px] px-4 text-[13px] ${selected ? "bg-ink text-surface" : "bg-surface"}`}
						>
							<span
								aria-hidden="true"
								className={`h-3 w-3 shrink-0 rounded-full ${CATEGORY_COLORS[custom.color].bg}`}
							/>
							<span>
								{custom.archived
									? `${custom.name} (${vi.categories.archivedTag})`
									: custom.name}
							</span>
						</OnlineButton>
					);
				})}
				<OnlineButton
					type="button"
					onClick={() => setManageOpen(true)}
					className="h-11 shrink-0 rounded-[22px] bg-sunken px-4 text-[13px] font-bold text-ink"
				>
					+ {vi.categories.add}
				</OnlineButton>
			</fieldset>
			<dialog
				ref={dialogRef}
				aria-labelledby={titleId}
				onClose={() => setManageOpen(false)}
				className="m-auto w-[calc(100%-32px)] max-w-[398px] rounded-[30px] bg-bg p-4 text-ink backdrop:bg-ink/40"
			>
				<div className="grid gap-3">
					<div className="flex items-center justify-between px-1">
						<h2 id={titleId} className="text-lg font-black">
							{vi.categories.title}
						</h2>
						<Button
							variant="surface"
							allowOffline
							className="h-11 px-4"
							onClick={() => setManageOpen(false)}
						>
							{vi.split.done}
						</Button>
					</div>
					<CategoryList groupId={groupId} />
				</div>
			</dialog>
		</>
	);
}
