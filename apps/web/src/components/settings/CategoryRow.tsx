"use client";
import { type CategoryDto, MemberColorCode } from "@songphang/contract";
import { useState } from "react";
import type { ApiError } from "../../lib/api";
import { useArchiveCategory, useUpdateCategory } from "../../lib/categories";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";

export const CATEGORY_COLORS: Record<
	CategoryDto["color"],
	{ bg: string; label: string }
> = {
	mint: { bg: "bg-mint", label: vi.categories.colors.mint },
	sky: { bg: "bg-sky", label: vi.categories.colors.sky },
	coral: { bg: "bg-coral", label: vi.categories.colors.coral },
	lilac: { bg: "bg-lilac", label: vi.categories.colors.lilac },
};

export function ColorSwatches({
	value,
	onChange,
	disabled,
}: {
	value: CategoryDto["color"];
	onChange: (next: CategoryDto["color"]) => void;
	disabled: boolean;
}) {
	return (
		<div className="flex items-center gap-2">
			{MemberColorCode.options.map((code) => (
				<button
					key={code}
					type="button"
					disabled={disabled}
					aria-label={t(vi.categories.colorLabel, {
						color: CATEGORY_COLORS[code].label,
					})}
					aria-pressed={value === code}
					onClick={() => onChange(code)}
					className={`flex h-11 w-11 items-center justify-center rounded-full ${value === code ? "ring-2 ring-ink ring-offset-2" : "bg-bg"}`}
				>
					<span
						className={`h-5 w-5 rounded-full ${CATEGORY_COLORS[code].bg}`}
					/>
				</button>
			))}
		</div>
	);
}

export function CategoryRow({
	groupId,
	category,
	disabled = false,
	onError,
}: {
	groupId: string;
	category: CategoryDto;
	disabled?: boolean;
	onError: (err: ApiError | null) => void;
}) {
	const [editing, setEditing] = useState(false);
	const [name, setName] = useState(category.name);
	const [color, setColor] = useState(category.color);
	const update = useUpdateCategory(groupId);
	const archive = useArchiveCategory(groupId);
	useSessionGuard(update.error ?? archive.error);
	const busy = disabled || update.isPending || archive.isPending;

	const save = () => {
		const trimmed = name.trim();
		if (!trimmed) return;
		onError(null);
		update.mutate(
			{
				id: category.id,
				request: {
					...(trimmed !== category.name ? { name: trimmed } : {}),
					...(color !== category.color ? { color } : {}),
				},
			},
			{
				onSuccess: () => setEditing(false),
				onError: (err) => onError(err),
			},
		);
	};

	if (!editing) {
		return (
			<div className="flex items-center gap-3 rounded-[20px] bg-bg px-3 py-2">
				<span
					aria-hidden="true"
					className={`h-3.5 w-3.5 shrink-0 rounded-full ${CATEGORY_COLORS[category.color].bg}`}
				/>
				<button
					type="button"
					disabled={busy}
					onClick={() => {
						setName(category.name);
						setColor(category.color);
						onError(null);
						setEditing(true);
					}}
					aria-label={t(vi.categories.edit, { name: category.name })}
					className="min-h-11 min-w-0 flex-1 break-words text-left text-sm font-bold text-ink disabled:opacity-60"
				>
					{category.name}
				</button>
				<button
					type="button"
					disabled={busy}
					onClick={() => {
						onError(null);
						archive.mutate(category.id, { onError: (err) => onError(err) });
					}}
					className="min-h-11 shrink-0 rounded-pill px-3 text-xs font-bold text-muted disabled:opacity-60"
				>
					{vi.categories.archive}
				</button>
			</div>
		);
	}

	const changed = name.trim() !== category.name || color !== category.color;
	return (
		<div className="grid gap-3 rounded-[20px] bg-bg p-3">
			<input
				aria-label={vi.categories.nameLabel}
				value={name}
				maxLength={30}
				disabled={busy}
				onChange={(event) => setName(event.target.value)}
				className="h-11 min-w-0 rounded-[16px] bg-surface px-3 text-sm font-bold text-ink disabled:opacity-60"
			/>
			<ColorSwatches value={color} onChange={setColor} disabled={busy} />
			<div className="flex gap-2">
				<Button
					variant="surface"
					className="h-11 flex-1"
					onClick={() => setEditing(false)}
				>
					{vi.common.cancel}
				</Button>
				<Button
					variant="primary"
					className="h-11 flex-1"
					disabled={busy || !name.trim() || !changed}
					onClick={save}
				>
					{vi.categories.saveName}
				</Button>
			</div>
		</div>
	);
}
