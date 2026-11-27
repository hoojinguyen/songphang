"use client";
import type {
	OverviewPendingAction,
	OverviewRecurringDueAction,
} from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { formatCalendarDateVN } from "../../lib/recurring-expenses";
import { t, vi } from "../../messages/vi";

export function PendingActionsList({
	actions,
	dueRecurringActions = [],
}: {
	actions: OverviewPendingAction[];
	dueRecurringActions?: OverviewRecurringDueAction[];
}) {
	const totalCount = actions.length + dueRecurringActions.length;
	if (totalCount === 0) return null;

	return (
		<section className="grid gap-3">
			<div className="flex items-center justify-between">
				<h2 className="text-base font-extrabold text-ink">
					{vi.overview.pendingActions}
				</h2>
				<span className="rounded-full bg-coral px-2 py-0.5 text-xs font-black text-on-accent">
					{totalCount}
				</span>
			</div>
			<div className="grid gap-2">
				{dueRecurringActions.map((item) => (
					<Link
						key={`recurring-${item.id}`}
						href={`/g/${encodeURIComponent(item.groupId)}/tx/new?form=1&recurringId=${encodeURIComponent(item.id)}`}
						className="flex items-center justify-between gap-3 rounded-[24px] bg-surface p-4 transition-colors hover:bg-surface-raised"
					>
						<div className="min-w-0 flex-1">
							<div className="flex items-center gap-2">
								<span className="rounded-md bg-warning-soft px-1.5 py-0.5 text-[11px] font-bold text-warning">
									{vi.recurring.modeVariable}
								</span>
								<span className="truncate text-xs font-medium text-muted">
									{item.groupName}
								</span>
							</div>
							<p className="mt-1 truncate text-sm font-bold text-ink">
								{t(vi.recurring.overviewDueTemplate, {
									description: item.description,
								})}
							</p>
							<p className="text-xs text-muted">
								{item.payerName} · {formatCalendarDateVN(item.dueDate)}
							</p>
						</div>
						<div className="shrink-0 text-right">
							<p className="tabular-nums text-sm font-black text-ink">
								{item.suggestedAmount !== null
									? formatMoney(item.suggestedAmount)
									: vi.recurring.enterAmountShort}
							</p>
						</div>
					</Link>
				))}
				{actions.map((action) => {
					const href =
						action.kind === "settlement_confirmation"
							? `/g/${action.groupId}/balances`
							: `/g/${action.groupId}/tx/${action.id}/view`;
					const label =
						action.kind === "settlement_confirmation"
							? vi.overview.confirmSettlement
							: vi.overview.approveExpense;

					return (
						<Link
							key={action.id}
							href={href}
							className="flex items-center justify-between gap-3 rounded-[24px] bg-surface p-4 transition-colors hover:bg-surface-raised"
						>
							<div className="min-w-0 flex-1">
								<div className="flex items-center gap-2">
									<span className="rounded-md bg-accent/30 px-1.5 py-0.5 text-[11px] font-bold text-ink">
										{label}
									</span>
									<span className="truncate text-xs font-medium text-muted">
										{action.groupName}
									</span>
								</div>
								<p className="mt-1 truncate text-sm font-bold text-ink">
									{action.description || action.actorName}
								</p>
								<p className="text-xs text-muted">{action.actorName}</p>
							</div>
							<div className="shrink-0 text-right">
								<p className="text-base font-black text-ink">
									{formatMoney(action.amount)}
								</p>
							</div>
						</Link>
					);
				})}
			</div>
		</section>
	);
}
