"use client";
import type {
	MemberDto,
	SettlementVaultFilter,
	SettlementVaultItemDto,
} from "@songphang/contract";
import { formatVietnamDateTime } from "@songphang/core";
import Link from "next/link";
import { useState } from "react";
import { attachmentContentUrl } from "../../lib/attachments";
import { formatMoney } from "../../lib/money";
import { useSettlementVault } from "../../lib/settlement-vault";
import { vi } from "../../messages/vi";
import { paymentChannelLabel } from "../pay/TransferProofFields";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";
import { MemberShape } from "../ui/MemberShape";
import { PhotoViewer } from "../ui/PhotoViewer";

const FILTER_OPTIONS: Array<{ value: SettlementVaultFilter; label: string }> = [
	{ value: "all", label: vi.vault.filterAll },
	{ value: "pending", label: vi.vault.statusPending },
	{ value: "confirmed", label: vi.vault.statusConfirmed },
	{ value: "with_proof", label: vi.settlementProof.hasProof },
];

const STATUS_BADGES: Record<
	SettlementVaultItemDto["status"],
	{ label: string; className: string }
> = {
	pending: {
		label: vi.vault.statusPending,
		className: "bg-warning-soft text-warning",
	},
	confirmed: {
		label: vi.vault.statusConfirmed,
		className: "bg-credit-soft text-credit",
	},
	rejected: {
		label: vi.vault.statusRejected,
		className: "bg-sunken text-muted",
	},
	cancelled: {
		label: vi.vault.statusCancelled,
		className: "bg-sunken text-muted",
	},
};

export function SettlementVaultView({
	groupId,
	members,
}: {
	groupId: string;
	members: MemberDto[];
}) {
	const [filter, setFilter] = useState<SettlementVaultFilter>("all");
	const [viewingAttachmentId, setViewingAttachmentId] = useState<string | null>(
		null,
	);
	const vault = useSettlementVault(groupId, { filter });

	const pages = vault.data?.pages ?? [];
	const items = pages.flatMap((page) => page.items);
	const summary = pages[0]?.summary;

	return (
		<div className="grid gap-4">
			{summary && (
				<section className="grid grid-cols-3 gap-2 rounded-[26px] bg-surface p-4 text-center">
					<div className="min-w-0">
						<p className="text-[11px] font-bold text-muted">
							{vi.vault.confirmedTotal}
						</p>
						<p className="mt-1 truncate tabular-nums text-sm font-black text-ink">
							{formatMoney(summary.confirmedTotalAmount)}
						</p>
					</div>
					<div className="min-w-0">
						<p className="text-[11px] font-bold text-muted">
							{vi.vault.statusPending}
						</p>
						<p className="mt-1 tabular-nums text-sm font-black text-ink">
							{summary.pendingCount}
						</p>
					</div>
					<div className="min-w-0">
						<p className="text-[11px] font-bold text-muted">
							{vi.settlementProof.hasProof}
						</p>
						<p className="mt-1 tabular-nums text-sm font-black text-ink">
							{summary.proofCount}
						</p>
					</div>
				</section>
			)}

			<div className="flex flex-wrap gap-2">
				{FILTER_OPTIONS.map((option) => {
					const active = filter === option.value;
					return (
						<button
							key={option.value}
							type="button"
							aria-pressed={active}
							onClick={() => setFilter(option.value)}
							className={`min-h-11 rounded-pill px-3.5 text-xs font-bold transition-colors ${
								active
									? "bg-ink text-on-ink"
									: "bg-surface text-ink hover:bg-surface-elevated"
							}`}
						>
							{option.label}
						</button>
					);
				})}
			</div>

			{vault.isPending ? (
				<div aria-busy="true" className="grid gap-3">
					<div className="h-24 rounded-[24px] bg-sunken" />
					<div className="h-24 rounded-[24px] bg-sunken" />
				</div>
			) : vault.isError ? (
				<LoadError
					onRetry={() => {
						void vault.refetch();
					}}
					isRetrying={vault.isFetching}
				/>
			) : items.length === 0 ? (
				<div className="rounded-[28px] bg-surface p-8 text-center">
					<p className="text-sm font-semibold text-muted">{vi.vault.empty}</p>
				</div>
			) : (
				<div className="grid gap-3">
					{items.map((item) => {
						const from = members.find((m) => m.id === item.fromMemberId);
						const to = members.find((m) => m.id === item.toMemberId);
						const badge = STATUS_BADGES[item.status];
						const timestamp = formatVietnamDateTime(new Date(item.occurredAt));

						return (
							<article
								key={`${item.kind}-${item.id}`}
								className="grid gap-3 rounded-[24px] bg-surface p-4"
							>
								<div className="flex items-start justify-between gap-3">
									<div className="flex min-w-0 flex-1 items-center gap-2.5">
										{from && to ? (
											<div className="flex shrink-0 -space-x-1.5">
												<MemberShape {...from} size={28} />
												<MemberShape {...to} size={28} />
											</div>
										) : null}
										<div className="min-w-0 flex-1">
											<p className="truncate text-sm font-extrabold text-ink">
												{from?.name ?? vi.activity.someone} →{" "}
												{to?.name ?? vi.activity.someone}
											</p>
											<p className="mt-0.5 text-[11px] font-semibold text-muted">
												{timestamp}
											</p>
										</div>
									</div>
									<span className="shrink-0 whitespace-nowrap tabular-nums text-base font-black text-ink">
										{formatMoney(item.amount)}
									</span>
								</div>

								<div className="flex flex-wrap items-center justify-between gap-2">
									<div className="flex flex-wrap items-center gap-1.5">
										<span
											className={`rounded-pill px-2.5 py-0.5 text-[11px] font-bold ${badge.className}`}
										>
											{badge.label}
										</span>
										{item.channel && (
											<span className="rounded-pill bg-sunken px-2.5 py-0.5 text-[11px] font-bold text-ink">
												{paymentChannelLabel(item.channel)}
											</span>
										)}
										{item.note && (
											<span className="text-xs font-semibold text-muted">
												{`“${item.note}”`}
											</span>
										)}
									</div>
									{item.transactionId && (
										<Link
											href={`/g/${encodeURIComponent(groupId)}/tx/${encodeURIComponent(item.transactionId)}/view`}
											className="inline-flex min-h-11 items-center px-2 text-xs font-bold text-ink underline"
										>
											{vi.feed.view}
										</Link>
									)}
								</div>

								{item.attachments.length > 0 && (
									<div className="flex flex-wrap gap-2">
										{item.attachments.map((attachment) => (
											<button
												key={attachment.id}
												type="button"
												aria-label={vi.settlementProof.viewProof}
												onClick={() => setViewingAttachmentId(attachment.id)}
												className="h-11 w-11 overflow-hidden rounded-[12px] bg-sunken"
											>
												<img
													src={attachmentContentUrl(groupId, attachment.id)}
													alt={vi.settlementProof.viewProof}
													className="h-11 w-11 object-cover"
												/>
											</button>
										))}
									</div>
								)}
							</article>
						);
					})}

					{vault.hasNextPage && (
						<Button
							variant="surface"
							disabled={vault.isFetchingNextPage}
							onClick={() => {
								void vault.fetchNextPage();
							}}
						>
							{vi.notifications.loadMore}
						</Button>
					)}
				</div>
			)}

			{viewingAttachmentId && (
				<PhotoViewer
					src={attachmentContentUrl(groupId, viewingAttachmentId)}
					alt={vi.settlementProof.viewProof}
					onClose={() => setViewingAttachmentId(null)}
				/>
			)}
		</div>
	);
}
