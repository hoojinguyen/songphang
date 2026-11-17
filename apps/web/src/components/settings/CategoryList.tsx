"use client";
import type { CategoryDto } from "@songphang/contract";
import { useState } from "react";
import type { ApiError } from "../../lib/api";
import { useCategories, useCreateCategory } from "../../lib/categories";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";
import { CategoryRow, ColorSwatches } from "./CategoryRow";

function categoryErrorText(error: ApiError | null): string | null {
	if (!error) return null;
	if (error.code === "CATEGORY_EXISTS") return vi.categories.duplicate;
	if (error.code === "LIMIT_REACHED") return vi.categories.limitReached;
	if (error.status === 403) return vi.common.forbidden;
	return vi.common.saveError;
}

export function CategoryList({ groupId }: { groupId: string }) {
	const query = useCategories(groupId);
	const create = useCreateCategory(groupId);
	useSessionGuard(query.error ?? create.error);
	const [newName, setNewName] = useState("");
	const [newColor, setNewColor] = useState<CategoryDto["color"]>("mint");
	const [idempotencyKey, setIdempotencyKey] = useState(() =>
		crypto.randomUUID(),
	);
	const [error, setError] = useState<ApiError | null>(null);

	if (query.isPending)
		return <div aria-busy="true" className="h-40 rounded-card bg-sunken" />;
	if (query.isError)
		return (
			<LoadError
				onRetry={() => {
					void query.refetch();
				}}
				isRetrying={query.isFetching}
			/>
		);

	const live = query.data.filter((c) => !c.archived);
	const addCategory = () => {
		const trimmed = newName.trim();
		if (!trimmed || create.isPending) return;
		setError(null);
		create.mutate(
			{
				request: { name: trimmed, color: newColor },
				key: idempotencyKey,
			},
			{
				onSuccess: () => {
					setNewName("");
					setIdempotencyKey(crypto.randomUUID());
				},
				onError: (err) => {
					setError(err);
					setIdempotencyKey(crypto.randomUUID());
				},
			},
		);
	};

	const errorText = categoryErrorText(error);
	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.categories.title}</h2>
			{live.length > 0 && (
				<div className="grid gap-2">
					{live.map((category) => (
						<CategoryRow
							key={category.id}
							groupId={groupId}
							category={category}
							onError={setError}
						/>
					))}
				</div>
			)}
			<div className="grid gap-2 pt-1">
				<input
					aria-label={vi.categories.nameLabel}
					placeholder={vi.categories.nameLabel}
					value={newName}
					maxLength={30}
					onChange={(event) => setNewName(event.target.value)}
					className="h-12 min-w-0 rounded-[20px] bg-bg px-3 text-sm font-bold text-ink"
				/>
				<ColorSwatches
					value={newColor}
					onChange={setNewColor}
					disabled={create.isPending}
				/>
				<Button
					variant="surface"
					className="h-12 bg-bg"
					disabled={create.isPending || !newName.trim()}
					onClick={addCategory}
				>
					{vi.categories.add}
				</Button>
			</div>
			{errorText && (
				<p role="alert" className="text-sm font-bold text-ink">
					{errorText}
				</p>
			)}
		</section>
	);
}
