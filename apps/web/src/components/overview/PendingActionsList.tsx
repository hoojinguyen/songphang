"use client";
import type { OverviewPendingAction } from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { vi } from "../../messages/vi";

export function PendingActionsList({
	actions,
}: {
	actions: OverviewPendingAction[];
}) {
	if (actions.length === 0) return null;

	return (
		<section className="grid gap-3">
			<div className="flex items-center justify-between">
				<h2 className="text-base font-extrabold text-ink">
					{vi.overview.pendingActions}
				</h2>
				<span className="rounded-full bg-coral px-2 py-0.5 text-xs font-black text-ink">
					{actions.length}
				</span>
			</div>
			<div className="grid gap-2">
				{actions.map((action) => {
					const href =
						action.kind === "settlement_confirmation"
							? `/g/${action.groupId}/balances`
							: `/g/${action.groupId}/tx/${action.id}`;
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
