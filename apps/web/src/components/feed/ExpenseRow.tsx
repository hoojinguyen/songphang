"use client";
import type {
	CategoryDto,
	MemberDto,
	TransactionListItemDto,
} from "@songphang/contract";
import { formatAmount, formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { CATEGORY_COLORS } from "../settings/CategoryRow";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";

export function ExpenseRow({
	transaction,
	members,
	categories = [],
	myMemberId,
}: {
	transaction: TransactionListItemDto;
	members: MemberDto[];
	categories?: CategoryDto[];
	myMemberId: string | null;
}) {
	const customCategory = transaction.categoryId
		? categories.find((category) => category.id === transaction.categoryId)
		: undefined;
	const categoryLabel = transaction.category
		? vi.expenseForm.categories[transaction.category]
		: customCategory?.name;

	const payer = members.find(
		(member) => member.id === transaction.payers[0]?.memberId,
	);
	const isMine =
		myMemberId !== null &&
		transaction.payers.some((entry) => entry.memberId === myMemberId);

	const payerLine =
		transaction.payers.length > 1
			? transaction.payers
					.map((entry) => {
						const member = members.find((m) => m.id === entry.memberId);
						const label =
							entry.memberId === myMemberId
								? vi.feed.youPaid
								: t(vi.feed.memberPaid, {
										name: member?.name ?? vi.activity.someone,
									});
						return `${label} ${formatMoney(entry.amount)}`;
					})
					.join(" · ")
			: isMine
				? vi.feed.youPaid
				: t(vi.feed.memberPaid, {
						name: payer?.name ?? vi.activity.someone,
					});

	const method = transaction.split.method;
	const methodLabel =
		method === "exact"
			? vi.feed.splitExact
			: method === "shares"
				? vi.feed.splitShares
				: method === "items"
					? vi.split.methodItems
					: method === "equal"
						? vi.split.methodEqual
						: vi.feed.splitPercent;

	const approvalStatus = transaction.approval.status;
	const uncounted =
		approvalStatus === "pending" || approvalStatus === "rejected";

	const timeStr = new Date(transaction.occurredAt).toLocaleTimeString("vi-VN", {
		hour: "2-digit",
		minute: "2-digit",
	});

	// Server myDelta
	const delta = transaction.myDelta;
	const myShare = transaction.shares.find(
		(share) => share.memberId === myMemberId,
	);

	return (
		<div
			className={`w-full rounded-[24px] bg-surface p-4 text-ink transition-colors hover:bg-surface-raised ${uncounted ? "opacity-85" : ""}`}
		>
			{/* Top row: Payer shape + name + timestamp + indicators */}
			<div className="flex items-center justify-between gap-2 text-xs font-semibold text-muted">
				<div className="flex items-center gap-2 min-w-0">
					{payer && <MemberShape {...payer} size={28} />}
					<span className="truncate font-bold text-ink">{payerLine}</span>
					<span>·</span>
					<span className="shrink-0">{timeStr}</span>
				</div>
				<div className="flex items-center gap-1.5 shrink-0">
					{approvalStatus === "pending" && (
						<span className="rounded-[10px] bg-accent px-2 py-0.5 text-[11px] font-bold text-ink">
							{vi.approval.pendingTag}
						</span>
					)}
					{approvalStatus === "rejected" && (
						<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[11px] font-bold text-ink">
							{vi.approval.rejectedTag}
						</span>
					)}
					{transaction.dispute !== null && (
						<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[11px] font-bold text-ink">
							{vi.transactionView.disputeTag}
						</span>
					)}
					{transaction.commentCount > 0 && (
						<span className="inline-flex items-center gap-1 text-[11px] font-bold text-muted">
							<Icon name="comment" size={13} />
							<span aria-hidden="true">{transaction.commentCount}</span>
							<span className="sr-only">
								{t(vi.transactionView.commentCount, {
									count: String(transaction.commentCount),
								})}
							</span>
						</span>
					)}
					{transaction.version > 1 && (
						<span className="text-[11px] font-bold text-muted">
							{vi.feed.edited}
						</span>
					)}
				</div>
			</div>

			{/* Middle row: Description + category on left; Total Amount above myDelta on right */}
			<div className="mt-2.5 flex items-start justify-between gap-3">
				<div className="min-w-0 flex-1">
					<p className="line-clamp-2 text-[15px] font-extrabold text-ink">
						{transaction.description}
					</p>
					{(categoryLabel || transaction.attachmentCount > 0) && (
						<div className="mt-1 flex items-center gap-1.5">
							{categoryLabel && (
								<span className="inline-flex items-center gap-1 rounded-md bg-sunken px-2 py-0.5 text-[11px] font-semibold text-ink">
									{customCategory && (
										<span
											aria-hidden="true"
											className={`size-2 shrink-0 rounded-full ${CATEGORY_COLORS[customCategory.color].bg}`}
										/>
									)}
									<span>{categoryLabel}</span>
								</span>
							)}
							{transaction.attachmentCount > 0 && (
								<span className="inline-flex items-center gap-1 text-[11px] text-muted">
									<Icon name="image" size={13} />
									{transaction.attachmentCount > 1 && (
										<span>{transaction.attachmentCount}</span>
									)}
								</span>
							)}
						</div>
					)}
				</div>

				<div className="shrink-0 text-right">
					<p className="tabular-nums text-lg font-black text-ink">
						{formatAmount(transaction.amount)} {vi.common.currency}
					</p>
					<div className="tabular-nums text-xs">
						{delta !== undefined && delta !== null ? (
							delta > 0 ? (
								<span className="font-bold text-credit">
									+{formatMoney(delta)}
								</span>
							) : delta < 0 ? (
								<span className="font-bold text-debt">
									−{formatMoney(Math.abs(delta))}
								</span>
							) : (
								<span className="font-medium text-muted">
									{vi.ledger.notParticipating}
								</span>
							)
						) : myShare ? (
							<span className="font-bold text-muted">
								{formatMoney(myShare.amount)}
							</span>
						) : (
							<span className="font-medium text-muted">
								{vi.ledger.notParticipating}
							</span>
						)}
					</div>
				</div>
			</div>

			{/* Bottom row: Up to 5 participant shapes cluster + +N + split method label */}
			<div className="mt-3 flex items-center justify-between border-t border-sunken pt-2.5 text-xs text-muted">
				<div className="flex items-center gap-1.5">
					<div className="flex -space-x-1.5">
						{transaction.shares.slice(0, 5).map((share) => {
							const member = members.find((m) => m.id === share.memberId);
							return member ? (
								<div
									key={share.memberId}
									className="rounded-full ring-2 ring-surface"
								>
									<MemberShape {...member} size={20} />
								</div>
							) : null;
						})}
					</div>
					{transaction.shares.length > 5 && (
						<span className="font-bold text-muted">
							+{transaction.shares.length - 5}
						</span>
					)}
				</div>
				<span className="font-semibold text-muted">{methodLabel}</span>
			</div>
		</div>
	);
}
