"use client";
import type { BudgetDto } from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";

export function BudgetBanner({
	groupId,
	budget,
}: {
	groupId: string;
	budget: BudgetDto | null | undefined;
}) {
	if (!budget || budget.state === "ok") return null;
	const isOver = budget.state === "over";
	const message = isOver
		? t(vi.budget.overBanner, {
				over: formatMoney(budget.spent - budget.amount),
			})
		: t(vi.budget.nearBanner, {
				spent: formatMoney(budget.spent),
				amount: formatMoney(budget.amount),
			});
	return (
		<Link
			href={`/g/${encodeURIComponent(groupId)}/stats`}
			className={`flex min-h-11 items-center rounded-[22px] px-4 py-2 text-xs font-bold ${
				isOver ? "bg-coral text-on-accent" : "bg-sunken text-ink"
			}`}
		>
			{message}
		</Link>
	);
}
