"use client";
import type { CurrentPeriodSummaryDto } from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import { formatMoney } from "../../lib/money";
import { useCloseSettlementCycle } from "../../lib/settlement-cycles";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";

function formatShortDate(iso: string): string {
	const date = new Date(iso);
	return `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`;
}

export function CloseCycleModal({
	open,
	groupId,
	nextCycleNumber,
	currentPeriod,
	onClose,
}: {
	open: boolean;
	groupId: string;
	nextCycleNumber: number;
	currentPeriod: CurrentPeriodSummaryDto;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const defaultTitle = t(vi.cycles.defaultTitle, {
		number: String(nextCycleNumber),
	});
	const [title, setTitle] = useState(defaultTitle);
	const [key, setKey] = useState(() => crypto.randomUUID());
	const mutation = useCloseSettlementCycle(groupId);
	useSessionGuard(mutation.error);

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			setTitle(t(vi.cycles.defaultTitle, { number: String(nextCycleNumber) }));
			setKey(crypto.randomUUID());
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open, nextCycleNumber]);

	const canSubmit =
		currentPeriod.countedTransactionCount > 0 &&
		title.trim().length > 0 &&
		!mutation.isPending;

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto w-[calc(100%-32px)] max-w-[398px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
		>
			<div className="grid gap-4">
				<h2 id={titleId} className="text-lg font-black">
					{vi.cycles.closeTitle}
				</h2>

				<div className="grid gap-1 rounded-[20px] bg-surface p-3.5 text-xs">
					<p className="font-semibold text-muted">
						{formatShortDate(currentPeriod.startedAt)} –{" "}
						{formatShortDate(new Date().toISOString())}
					</p>
					<p className="tabular-nums text-sm font-black text-ink">
						{currentPeriod.expenseCount} ·{" "}
						{formatMoney(currentPeriod.totalExpenseAmount)}
					</p>
				</div>

				<label className="grid gap-1.5 text-xs font-bold text-muted">
					{vi.cycles.titleLabel}
					<input
						type="text"
						maxLength={80}
						value={title}
						onChange={(event) => setTitle(event.target.value)}
						className="h-12 min-w-0 rounded-[20px] bg-surface px-3.5 text-sm font-bold text-ink"
					/>
				</label>

				<p className="rounded-[18px] bg-sunken p-3 text-xs font-semibold text-muted">
					{vi.cycles.carryOverNote}
				</p>

				{currentPeriod.countedTransactionCount === 0 && (
					<p role="status" className="text-xs font-bold text-muted">
						{vi.cycles.emptyPeriodError}
					</p>
				)}

				{mutation.isError && (
					<p role="alert" className="text-xs font-bold text-debt">
						{mutation.error.code === "CYCLE_EMPTY"
							? vi.cycles.emptyPeriodError
							: mutation.error.status === 403
								? vi.common.forbidden
								: vi.common.saveError}
					</p>
				)}

				<div className="flex gap-2">
					<Button
						variant="surface"
						allowOffline
						className="flex-1"
						onClick={onClose}
					>
						{vi.common.cancel}
					</Button>
					<Button
						variant="accent"
						className="flex-1"
						disabled={!canSubmit}
						onClick={() => {
							if (!canSubmit) return;
							mutation.mutate(
								{ title: title.trim(), key },
								{
									onSuccess: () => onClose(),
								},
							);
						}}
					>
						{vi.cycles.closeAction}
					</Button>
				</div>
			</div>
		</dialog>
	);
}
