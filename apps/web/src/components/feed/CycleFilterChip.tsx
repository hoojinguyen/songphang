"use client";
import type {
	CurrentPeriodSummaryDto,
	SettlementCycleDto,
} from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import { formatMoney } from "../../lib/money";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";

function formatShortDate(iso: string): string {
	const date = new Date(iso);
	return `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`;
}

export function CycleFilterChip({
	cycles,
	currentPeriod,
	selectedCycleId,
	onSelect,
}: {
	cycles: SettlementCycleDto[];
	currentPeriod: CurrentPeriodSummaryDto;
	selectedCycleId: "current" | string | undefined;
	onSelect: (cycleId: "current" | string | undefined) => void;
}) {
	const [open, setOpen] = useState(false);
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open]);

	if (cycles.length === 0) return null;

	const selectedCycle =
		selectedCycleId && selectedCycleId !== "current"
			? cycles.find((cycle) => cycle.id === selectedCycleId)
			: undefined;

	const label =
		selectedCycleId === "current"
			? `${vi.cycles.currentPeriod} (${currentPeriod.countedTransactionCount})`
			: selectedCycle
				? selectedCycle.title
				: vi.cycles.allPeriods;

	return (
		<>
			<div className="flex items-center">
				<button
					type="button"
					onClick={() => setOpen(true)}
					className="inline-flex min-h-11 items-center gap-2 rounded-pill bg-surface px-4 text-xs font-extrabold text-ink transition-colors hover:bg-surface-elevated"
				>
					<span>{label}</span>
				</button>
			</div>

			<dialog
				ref={dialogRef}
				aria-labelledby={titleId}
				onClose={() => setOpen(false)}
				className="m-auto w-[calc(100%-32px)] max-w-[390px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
			>
				<div className="grid gap-3">
					<div className="flex items-center justify-between gap-2">
						<h2 id={titleId} className="text-base font-black">
							{vi.cycles.selectPeriod}
						</h2>
						<button
							type="button"
							aria-label={vi.common.cancel}
							onClick={() => setOpen(false)}
							className="flex h-11 w-11 items-center justify-center rounded-full bg-surface text-ink"
						>
							<Icon name="close" size={16} />
						</button>
					</div>

					<button
						type="button"
						onClick={() => {
							onSelect("current");
							setOpen(false);
						}}
						className={`flex min-h-11 items-center justify-between rounded-[18px] px-4 py-3 text-left text-sm font-bold ${
							selectedCycleId === "current"
								? "bg-ink text-on-ink"
								: "bg-surface text-ink"
						}`}
					>
						<span>{vi.cycles.currentPeriod}</span>
						<span className="tabular-nums text-xs opacity-80">
							{currentPeriod.countedTransactionCount} ·{" "}
							{formatMoney(currentPeriod.totalExpenseAmount)}
						</span>
					</button>

					<button
						type="button"
						onClick={() => {
							onSelect(undefined);
							setOpen(false);
						}}
						className={`flex min-h-11 items-center justify-between rounded-[18px] px-4 py-3 text-left text-sm font-bold ${
							selectedCycleId === undefined
								? "bg-ink text-on-ink"
								: "bg-surface text-ink"
						}`}
					>
						<span>{vi.cycles.allPeriods}</span>
					</button>

					<div className="grid max-h-[40dvh] gap-2 overflow-y-auto">
						{cycles.map((cycle) => (
							<button
								key={cycle.id}
								type="button"
								onClick={() => {
									onSelect(cycle.id);
									setOpen(false);
								}}
								className={`flex min-h-11 items-center justify-between gap-3 rounded-[18px] px-4 py-3 text-left text-sm font-bold ${
									selectedCycleId === cycle.id
										? "bg-ink text-on-ink"
										: "bg-surface text-ink"
								}`}
							>
								<div className="min-w-0">
									<p className="truncate">{cycle.title}</p>
									<p className="text-[11px] font-semibold opacity-75">
										{formatShortDate(cycle.startedAt)} –{" "}
										{formatShortDate(cycle.closedAt)}
									</p>
								</div>
								<span className="shrink-0 tabular-nums text-xs opacity-80">
									{formatMoney(cycle.totalExpenseAmount)}
								</span>
							</button>
						))}
					</div>
				</div>
			</dialog>
		</>
	);
}
