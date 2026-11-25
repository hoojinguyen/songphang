"use client";
import type { GuestMemberDto, GuestTransactionDto } from "@songphang/contract";
import { formatVietnamDateTime } from "@songphang/core";
import { useEffect, useId, useRef, useState } from "react";
import { guestAttachmentContentUrl } from "../../lib/attachments";
import { formatAmount, formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { paymentChannelLabel } from "../pay/TransferProofFields";
import { CATEGORY_COLORS } from "../settings/CategoryRow";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { PhotoViewer } from "../ui/PhotoViewer";

export function GuestExpenseDetailModal({
	token,
	transaction,
	members,
	onClose,
}: {
	token: string;
	transaction: GuestTransactionDto | null;
	members: GuestMemberDto[];
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const [viewingAttachmentId, setViewingAttachmentId] = useState<string | null>(
		null,
	);

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (transaction && !dialog.open) {
			setViewingAttachmentId(null);
			dialog.showModal();
		} else if (!transaction && dialog.open) {
			dialog.close();
		}
	}, [transaction]);

	if (!transaction) {
		return <dialog ref={dialogRef} className="hidden" />;
	}

	const memberName = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;
	const categoryLabel = transaction.category
		? vi.expenseForm.categories[transaction.category]
		: (transaction.categoryName ?? null);

	return (
		<>
			<dialog
				ref={dialogRef}
				aria-labelledby={titleId}
				onClose={onClose}
				className="m-auto max-h-[88dvh] w-[calc(100%-24px)] max-w-[430px] overflow-hidden rounded-[30px] bg-bg p-0 text-ink backdrop:bg-ink/45"
			>
				<div className="flex max-h-[88dvh] flex-col">
					<div className="flex items-center justify-between gap-3 border-b border-sunken px-5 py-4">
						<div className="min-w-0">
							<p className="text-xs font-semibold text-muted">
								{formatVietnamDateTime(new Date(transaction.occurredAt))}
							</p>
							<h2 id={titleId} className="truncate text-base font-black">
								{transaction.description}
							</h2>
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
						<p className="tabular-nums text-[36px] font-black leading-tight">
							{formatAmount(transaction.amount)}{" "}
							<span className="text-base font-bold text-muted">
								{vi.common.currency}
							</span>
						</p>

						<div className="flex flex-wrap gap-2 text-xs font-bold">
							{categoryLabel && (
								<span className="inline-flex items-center gap-1.5 rounded-pill bg-surface px-3 py-1.5">
									{transaction.categoryColor && (
										<span
											aria-hidden="true"
											className={`size-2.5 rounded-full ${CATEGORY_COLORS[transaction.categoryColor].bg}`}
										/>
									)}
									<span>{categoryLabel}</span>
								</span>
							)}
							{transaction.type === "transfer" &&
								transaction.paymentChannel && (
									<span className="rounded-pill bg-surface px-3 py-1.5">
										{paymentChannelLabel(transaction.paymentChannel)}
									</span>
								)}
						</div>

						{transaction.type === "transfer" && transaction.paymentNote && (
							<p className="rounded-[18px] bg-surface px-3.5 py-2.5 text-sm font-semibold text-ink">
								{`“${transaction.paymentNote}”`}
							</p>
						)}

						<section className="grid gap-2 rounded-[22px] bg-surface p-4 text-xs">
							<h3 className="font-extrabold text-muted">
								{transaction.type === "transfer"
									? vi.expenseForm.transferFrom
									: vi.expenseForm.payerTitle}
							</h3>
							{transaction.payers.map((payer) => {
								const member = members.find((m) => m.id === payer.memberId);
								return (
									<div
										key={payer.memberId}
										className="flex items-center justify-between gap-2"
									>
										<div className="flex min-w-0 items-center gap-2">
											{member && <MemberShape {...member} size={22} />}
											<span className="truncate font-bold text-ink">
												{member?.name ?? vi.activity.someone}
											</span>
										</div>
										<span className="shrink-0 tabular-nums font-extrabold text-ink">
											{formatMoney(payer.amount)}
										</span>
									</div>
								);
							})}
						</section>

						{transaction.split.method === "items" && (
							<section className="grid gap-2 rounded-[22px] bg-surface p-4 text-xs">
								<h3 className="font-extrabold text-muted">
									{vi.split.methodItems}
								</h3>
								{(() => {
									const counts = new Map<string, number>();
									return transaction.split.items.map((item) => {
										const base = `${item.name}:${item.amount}:${item.memberIds.join(",")}`;
										const seen = (counts.get(base) ?? 0) + 1;
										counts.set(base, seen);
										return (
											<div
												key={`${base}#${seen}`}
												className="flex items-start justify-between gap-2"
											>
												<span className="min-w-0 font-semibold text-ink">
													{item.name}
													{item.memberIds.length > 0 && (
														<span className="ml-1 font-normal text-muted">
															({item.memberIds.map(memberName).join(", ")})
														</span>
													)}
												</span>
												<span className="shrink-0 tabular-nums font-bold">
													{formatMoney(item.amount)}
												</span>
											</div>
										);
									});
								})()}
								{(() => {
									const counts = new Map<string, number>();
									return transaction.split.extras.map((extra) => {
										const base = `${extra.kind}:${extra.label}:${extra.amount}`;
										const seen = (counts.get(base) ?? 0) + 1;
										counts.set(base, seen);
										return (
											<div
												key={`${base}#${seen}`}
												className="flex items-center justify-between gap-2 border-t border-sunken pt-1.5 text-muted"
											>
												<span>
													{extra.label || vi.receipts.extrasKinds[extra.kind]}
												</span>
												<span className="tabular-nums font-bold">
													{extra.kind === "discount" ? "−" : "+"}
													{formatMoney(extra.amount)}
												</span>
											</div>
										);
									});
								})()}
							</section>
						)}

						{transaction.shares.length > 0 && (
							<section className="grid gap-2 rounded-[22px] bg-surface p-4 text-xs">
								<h3 className="font-extrabold text-muted">
									{transaction.type === "transfer"
										? vi.expenseForm.transferTo
										: vi.expenseForm.sharersTitle}
								</h3>
								{transaction.shares.map((share) => {
									const member = members.find((m) => m.id === share.memberId);
									return (
										<div
											key={share.memberId}
											className="flex items-center justify-between gap-2"
										>
											<div className="flex min-w-0 items-center gap-2">
												{member && <MemberShape {...member} size={22} />}
												<span className="truncate font-bold text-ink">
													{member?.name ?? vi.activity.someone}
												</span>
											</div>
											<span className="shrink-0 tabular-nums font-extrabold text-ink">
												{formatMoney(share.amount)}
											</span>
										</div>
									);
								})}
							</section>
						)}

						{transaction.type !== "transfer" &&
							transaction.attachments.length > 0 && (
								<section className="grid gap-2 rounded-[22px] bg-surface p-4">
									<h3 className="text-xs font-extrabold text-muted">
										{t(vi.attachments.label, {})}
									</h3>
									<div className="flex flex-wrap gap-2">
										{transaction.attachments.map((attachment) => (
											<button
												key={attachment.id}
												type="button"
												aria-label={vi.attachments.viewPhoto}
												onClick={() => setViewingAttachmentId(attachment.id)}
												className="h-16 w-16 overflow-hidden rounded-[14px] bg-sunken"
											>
												<img
													src={guestAttachmentContentUrl(token, attachment.id)}
													alt={vi.attachments.label}
													className="h-16 w-16 object-cover"
												/>
											</button>
										))}
									</div>
								</section>
							)}
					</div>
				</div>
			</dialog>

			{viewingAttachmentId && (
				<PhotoViewer
					src={guestAttachmentContentUrl(token, viewingAttachmentId)}
					alt={vi.attachments.label}
					onClose={() => setViewingAttachmentId(null)}
				/>
			)}
		</>
	);
}
