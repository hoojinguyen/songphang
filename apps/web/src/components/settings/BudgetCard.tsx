"use client";
import type { BudgetPeriod } from "@songphang/contract";
import { useState } from "react";
import { useBudget, useDeleteBudget, usePutBudget } from "../../lib/budget";
import { formatAmount, parseAmountInput } from "../../lib/money";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { AmountField } from "../expense-form/AmountField";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";
import { SegmentedControl } from "../ui/SegmentedControl";

export function BudgetCard({ groupId }: { groupId: string }) {
	const query = useBudget(groupId);
	const save = usePutBudget(groupId);
	const remove = useDeleteBudget(groupId);
	const [draft, setDraft] = useState<{
		period: BudgetPeriod;
		amountText: string;
	} | null>(null);
	useSessionGuard(query.error ?? save.error ?? remove.error);

	if (query.isPending)
		return <div aria-busy="true" className="h-44 rounded-card bg-sunken" />;
	if (query.isError)
		return (
			<LoadError
				onRetry={() => {
					void query.refetch();
				}}
				isRetrying={query.isFetching}
			/>
		);

	const existing = query.data;
	const period: BudgetPeriod = draft?.period ?? existing?.period ?? "month";
	const amountText =
		draft?.amountText ?? (existing ? formatAmount(existing.amount) : "");
	const parsed = parseAmountInput(amountText);
	const valid = parsed !== null && parsed >= 1 && parsed <= 999_999_999_999;
	const busy = save.isPending || remove.isPending;
	const unchanged =
		existing !== null &&
		period === existing.period &&
		parsed === existing.amount;
	const mutError = save.error ?? remove.error;

	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.budget.title}</h2>
			<SegmentedControl
				label={vi.budget.title}
				value={period}
				options={[
					{ value: "month", label: vi.budget.periodMonth },
					{ value: "total", label: vi.budget.periodTotal },
				]}
				disabled={busy}
				onChange={(next) => {
					if (next === "month" || next === "total") {
						setDraft({ period: next, amountText });
					}
				}}
			/>
			<div className="grid gap-1.5">
				<span className="text-[13px] font-semibold text-muted">
					{vi.budget.amountLabel}
				</span>
				<AmountField
					value={amountText}
					onChange={(next) => setDraft({ period, amountText: next })}
					autoFocus={false}
					label={vi.budget.amountLabel}
				/>
			</div>
			{mutError && (
				<p role="alert" className="text-xs font-semibold text-debt">
					{mutError.status === 403 ? vi.common.forbidden : vi.common.saveError}
				</p>
			)}
			<div className="flex flex-wrap gap-2">
				<Button
					variant="primary"
					className="flex-1"
					disabled={busy || !valid || unchanged}
					onClick={() => {
						if (!valid) return;
						save.mutate(
							{ period, amount: parsed },
							{ onSuccess: () => setDraft(null) },
						);
					}}
				>
					{vi.budget.save}
				</Button>
				{existing && (
					<Button
						variant="surface"
						className="bg-sunken"
						disabled={busy}
						onClick={() => {
							remove.mutate(undefined, { onSuccess: () => setDraft(null) });
						}}
					>
						{vi.budget.remove}
					</Button>
				)}
			</div>
		</section>
	);
}
