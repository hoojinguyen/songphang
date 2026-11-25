"use client";
import type { SettlementCyclesResponse } from "@songphang/contract";
import { useState } from "react";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { useReopenSettlementCycle } from "../../lib/settlement-cycles";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { LoadError } from "../ui/LoadError";
import { MemberShape } from "../ui/MemberShape";
import { useSnackbar } from "../ui/Snackbar";

function formatShortDate(iso: string): string {
	const date = new Date(iso);
	return `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`;
}

export function SettlementCyclesView({
	groupId,
	role,
	isArchived,
	cyclesData,
	isPending,
	isError,
	isFetching,
	onRetry,
	onViewCycleExpenses,
}: {
	groupId: string;
	role: "owner" | "editor" | "viewer";
	isArchived: boolean;
	cyclesData: SettlementCyclesResponse | undefined;
	isPending: boolean;
	isError: boolean;
	isFetching: boolean;
	onRetry: () => void;
	onViewCycleExpenses: (cycleId: string) => void;
}) {
	const [expandedId, setExpandedId] = useState<string | null>(null);
	const [reopenCycleId, setReopenCycleId] = useState<string | null>(null);
	const reopen = useReopenSettlementCycle(groupId);
	const showNotice = useSnackbar();

	if (isPending) {
		return (
			<div aria-busy="true" className="grid gap-3">
				<div className="h-24 rounded-[26px] bg-sunken" />
				<div className="h-24 rounded-[26px] bg-sunken" />
			</div>
		);
	}
	if (isError) {
		return <LoadError onRetry={onRetry} isRetrying={isFetching} />;
	}

	const cycles = cyclesData?.cycles ?? [];
	if (cycles.length === 0) {
		return (
			<div className="rounded-[28px] bg-surface p-8 text-center">
				<p className="text-sm font-semibold text-muted">
					{vi.cycles.emptyPeriodError}
				</p>
			</div>
		);
	}

	return (
		<div className="grid gap-3">
			{cycles.map((cycle, index) => {
				const expanded = expandedId === cycle.id;
				const isLatest = index === 0;
				return (
					<section
						key={cycle.id}
						className="grid gap-3 rounded-[26px] bg-surface p-4"
					>
						<button
							type="button"
							aria-expanded={expanded}
							onClick={() => setExpandedId(expanded ? null : cycle.id)}
							className="flex min-h-11 w-full items-center justify-between gap-3 text-left"
						>
							<div className="min-w-0 flex-1">
								<p className="truncate text-base font-black text-ink">
									{cycle.title}
								</p>
								<p className="mt-0.5 text-xs font-semibold text-muted">
									{formatShortDate(cycle.startedAt)} –{" "}
									{formatShortDate(cycle.closedAt)} · {cycle.expenseCount}
								</p>
							</div>
							<span className="shrink-0 whitespace-nowrap tabular-nums text-sm font-black text-ink">
								{formatMoney(cycle.totalExpenseAmount)}
							</span>
						</button>

						{expanded && (
							<div className="grid gap-3 border-t border-sunken pt-3">
								<p className="text-[11px] font-extrabold uppercase tracking-wider text-muted">
									{vi.cycles.frozenSnapshotLabel}
								</p>

								{cycle.snapshot.transfers.length > 0 && (
									<div className="grid gap-1.5 rounded-[18px] bg-sunken p-3 text-xs">
										{cycle.snapshot.transfers.map((transfer) => (
											<div
												key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
												className="flex items-center justify-between gap-2"
											>
												<span className="min-w-0 truncate font-bold text-ink">
													{transfer.fromName} → {transfer.toName}
												</span>
												<span className="shrink-0 tabular-nums font-black text-ink">
													{formatMoney(transfer.amount)}
												</span>
											</div>
										))}
									</div>
								)}

								<div className="grid gap-1.5 text-xs">
									{cycle.snapshot.balances.map((entry) => (
										<div
											key={entry.memberId}
											className="flex items-center justify-between gap-2"
										>
											<div className="flex min-w-0 items-center gap-2">
												<MemberShape
													shape={entry.shape}
													color={entry.color}
													name={entry.name}
													size={20}
												/>
												<span className="truncate font-semibold text-ink">
													{entry.name}
												</span>
											</div>
											<span
												className={`shrink-0 tabular-nums font-bold ${
													entry.balance > 0
														? "text-credit"
														: entry.balance < 0
															? "text-debt"
															: "text-muted"
												}`}
											>
												{formatSignedAmount(entry.balance)} {vi.common.currency}
											</span>
										</div>
									))}
								</div>

								<div className="flex flex-wrap gap-2 pt-1">
									<Button
										variant="surface"
										allowOffline
										className="flex-1 bg-sunken text-xs"
										onClick={() => onViewCycleExpenses(cycle.id)}
									>
										{vi.cycles.viewExpensesAction}
									</Button>
									{isLatest && role === "owner" && !isArchived && (
										<Button
											variant="surface"
											className="bg-debt-soft text-xs text-ink"
											disabled={reopen.isPending}
											onClick={() => setReopenCycleId(cycle.id)}
										>
											{vi.cycles.reopenAction}
										</Button>
									)}
								</div>
							</div>
						)}
					</section>
				);
			})}

			{reopenCycleId && (
				<ConfirmDialog
					title={vi.cycles.reopenAction}
					body={vi.cycles.reopenConfirmBody}
					confirmLabel={vi.cycles.reopenAction}
					cancelLabel={vi.common.cancel}
					confirmDisabled={reopen.isPending}
					onCancel={() => setReopenCycleId(null)}
					onConfirm={() => {
						reopen.mutate(reopenCycleId, {
							onSuccess: () => setReopenCycleId(null),
							onError: () => {
								setReopenCycleId(null);
								showNotice({ text: vi.common.saveError });
							},
						});
					}}
				/>
			)}
		</div>
	);
}
