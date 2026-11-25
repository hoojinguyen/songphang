"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { useEffect, useId, useRef } from "react";
import { useMemberBreakdowns } from "../../lib/member-breakdowns";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { LoadError } from "../ui/LoadError";
import { MemberShape } from "../ui/MemberShape";

export function MemberBreakdownSheet({
	open,
	memberId,
	groupId,
	transfers,
	members,
	onClose,
}: {
	open: boolean;
	memberId: string | null;
	groupId: string;
	transfers: BalancesResponse["transfers"];
	members: MemberDto[];
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const query = useMemberBreakdowns(groupId, "auto", open && memberId !== null);

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

	const member = members.find((m) => m.id === memberId);
	const breakdown = query.data?.breakdowns.find((b) => b.memberId === memberId);
	const relevantTransfers = memberId
		? transfers.filter(
				(transfer) =>
					transfer.fromMemberId === memberId ||
					transfer.toMemberId === memberId,
			)
		: [];
	const showAllocation =
		breakdown !== undefined &&
		relevantTransfers.length > 0 &&
		(relevantTransfers.length > 1 ||
			Math.abs(breakdown.netBalance) !== relevantTransfers[0]?.amount);

	const memberName = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto max-h-[88dvh] w-[calc(100%-24px)] max-w-[430px] overflow-hidden rounded-[30px] bg-bg p-0 text-ink backdrop:bg-ink/45"
		>
			<div className="flex max-h-[88dvh] flex-col">
				<div className="flex items-center justify-between gap-3 border-b border-sunken px-5 py-4">
					<div className="flex min-w-0 items-center gap-3">
						{member && <MemberShape {...member} size={36} />}
						<div className="min-w-0">
							<h2 id={titleId} className="truncate text-base font-black">
								{member?.name ?? vi.breakdown.title}
							</h2>
							<p className="text-xs font-semibold text-muted">
								{vi.breakdown.title}
								{query.data?.resolvedFocus.label
									? ` · ${query.data.resolvedFocus.label}`
									: ""}
							</p>
						</div>
					</div>
					<button
						type="button"
						aria-label={vi.common.cancel}
						onClick={onClose}
						className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-surface text-ink"
					>
						<Icon name="close" size={18} />
					</button>
				</div>

				<div className="flex-1 space-y-4 overflow-y-auto p-5">
					{query.isPending ? (
						<div aria-busy="true" className="grid gap-3">
							<div className="h-28 rounded-[22px] bg-sunken" />
							<div className="h-44 rounded-[22px] bg-sunken" />
						</div>
					) : query.isError ? (
						<LoadError
							onRetry={() => {
								void query.refetch();
							}}
							isRetrying={query.isFetching}
						/>
					) : !breakdown ? null : (
						<>
							<section className="grid gap-2 rounded-[24px] bg-surface p-4 text-sm">
								{(query.data.hasClosedCycles ||
									breakdown.carryOverBalance !== 0) && (
									<div className="flex items-center justify-between gap-2">
										<span className="text-muted">{vi.breakdown.carryOver}</span>
										<span className="tabular-nums font-bold">
											{formatSignedAmount(breakdown.carryOverBalance)}{" "}
											{vi.common.currency}
										</span>
									</div>
								)}
								<div className="flex items-center justify-between gap-2">
									<span className="text-muted">
										{vi.breakdown.periodExpenses}
									</span>
									<span className="tabular-nums font-bold">
										{formatSignedAmount(breakdown.focusExpenseDelta)}{" "}
										{vi.common.currency}
									</span>
								</div>
								<div className="flex items-center justify-between gap-2">
									<span className="text-muted">
										{vi.breakdown.periodTransfers}
									</span>
									<span className="tabular-nums font-bold">
										{formatSignedAmount(breakdown.focusTransferDelta)}{" "}
										{vi.common.currency}
									</span>
								</div>
								{breakdown.postCycleDelta !== 0 && (
									<div className="flex items-center justify-between gap-2">
										<span className="text-muted">
											{vi.breakdown.postCycleDelta}
										</span>
										<span className="tabular-nums font-bold">
											{formatSignedAmount(breakdown.postCycleDelta)}{" "}
											{vi.common.currency}
										</span>
									</div>
								)}
								<div className="mt-1 flex items-center justify-between gap-2 border-t border-sunken pt-2.5 text-base font-black">
									<span>{vi.breakdown.currentBalance}</span>
									<span
										className={`tabular-nums ${
											breakdown.netBalance > 0
												? "text-credit"
												: breakdown.netBalance < 0
													? "text-debt"
													: "text-ink"
										}`}
									>
										{formatSignedAmount(breakdown.netBalance)}{" "}
										{vi.common.currency}
									</span>
								</div>
							</section>

							{breakdown.lines.length > 0 && (
								<section className="grid gap-2">
									{breakdown.lines.map((line) => {
										const date = new Date(line.occurredAt);
										const dateText = `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}`;
										return (
											<div
												key={line.transactionId}
												className="flex items-start justify-between gap-3 rounded-[20px] bg-surface px-3.5 py-3 text-xs"
											>
												<div className="min-w-0 flex-1">
													<p className="font-bold text-ink">
														{line.description}
													</p>
													<p className="mt-0.5 text-muted">
														{dateText} · {line.payerSummary} ·{" "}
														{formatMoney(line.totalAmount)}
													</p>
													{line.memberShare > 0 && (
														<p className="mt-0.5 text-muted">
															{vi.ledger.myShare}:{" "}
															{formatMoney(line.memberShare)}
														</p>
													)}
												</div>
												<span
													className={`shrink-0 whitespace-nowrap tabular-nums text-sm font-extrabold ${
														line.delta > 0
															? "text-credit"
															: line.delta < 0
																? "text-debt"
																: "text-muted"
													}`}
												>
													{formatSignedAmount(line.delta)} {vi.common.currency}
												</span>
											</div>
										);
									})}
								</section>
							)}

							{showAllocation && (
								<section className="grid gap-2 rounded-[22px] bg-surface p-4 text-xs">
									<h3 className="font-extrabold text-ink">
										{vi.breakdown.transferAllocation}
									</h3>
									{relevantTransfers.map((transfer) => (
										<div
											key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
											className="flex items-center justify-between gap-2"
										>
											<span className="min-w-0 truncate text-muted">
												{memberName(transfer.fromMemberId)} →{" "}
												{memberName(transfer.toMemberId)}
											</span>
											<span className="shrink-0 tabular-nums font-bold text-ink">
												{formatMoney(transfer.amount)}
											</span>
										</div>
									))}
								</section>
							)}
						</>
					)}
				</div>
			</div>
		</dialog>
	);
}
