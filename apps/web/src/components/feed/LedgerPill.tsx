import type { MemberDto, TransactionListItemDto } from "@songphang/contract";
import { attachmentContentUrl } from "../../lib/attachments";
import { formatAmount, formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { paymentChannelLabel } from "../pay/TransferProofFields";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";

export function LedgerPill({
	groupId,
	transaction,
	members,
	myMemberId,
}: {
	groupId: string;
	transaction: TransactionListItemDto;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const from = members.find((m) => m.id === transaction.payers[0]?.memberId);
	const to = members.find((m) => m.id === transaction.shares[0]?.memberId);
	if (!from) return null;
	const amount = formatMoney(transaction.amount);
	const approvalStatus = transaction.approval.status;
	const uncounted =
		approvalStatus === "pending" || approvalStatus === "rejected";

	if (transaction.type === "transfer" && to) {
		const hasProof =
			Boolean(transaction.firstAttachmentId) || transaction.attachmentCount > 0;
		const channelText = transaction.paymentChannel
			? paymentChannelLabel(transaction.paymentChannel)
			: null;
		const noteText = transaction.paymentNote
			? `“${transaction.paymentNote}”`
			: null;
		const subtitle = [channelText, noteText].filter(Boolean).join(" · ");
		const titleText =
			from.id === myMemberId
				? t(vi.balances.youPaidMember, { name: to.name })
				: to.id === myMemberId
					? t(vi.balances.memberPaidYou, { name: from.name })
					: t(vi.balances.memberPaidMember, {
							from: from.name,
							to: to.name,
						});

		return (
			<div
				className={`flex w-full items-center justify-between gap-3 rounded-[20px] bg-sunken px-3.5 py-2.5 text-xs ${uncounted ? "opacity-85" : ""}`}
			>
				<div className="flex min-w-0 flex-1 items-center gap-2.5">
					{transaction.firstAttachmentId ? (
						<img
							src={attachmentContentUrl(groupId, transaction.firstAttachmentId)}
							alt={vi.settlementProof.hasProof}
							className="size-7 shrink-0 rounded-[8px] object-cover"
						/>
					) : (
						<MemberShape {...from} size={24} />
					)}
					<div className="min-w-0 flex-1">
						<div className="flex flex-wrap items-center gap-1.5">
							<span className="truncate font-bold text-ink">{titleText}</span>
							{hasProof && (
								<span className="inline-flex shrink-0 items-center gap-1 rounded-pill bg-surface px-2 py-0.5 text-[10px] font-bold text-ink">
									<Icon name="image" size={11} />
									<span>{vi.settlementProof.hasProof}</span>
								</span>
							)}
							{approvalStatus === "pending" && (
								<span className="rounded-[10px] bg-accent px-2 py-0.5 text-[10px] font-bold text-on-accent">
									{vi.approval.pendingTag}
								</span>
							)}
							{approvalStatus === "rejected" && (
								<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[10px] font-bold text-on-accent">
									{vi.approval.rejectedTag}
								</span>
							)}
							{transaction.dispute !== null && (
								<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[10px] font-bold text-on-accent">
									{vi.transactionView.disputeTag}
								</span>
							)}
							{transaction.commentCount > 0 && (
								<span className="inline-flex items-center gap-1 text-[10px] font-bold text-muted">
									<Icon name="comment" size={12} />
									<span aria-hidden="true">{transaction.commentCount}</span>
								</span>
							)}
							{transaction.version > 1 && (
								<span className="text-[10px] font-bold text-muted">
									{vi.feed.edited}
								</span>
							)}
						</div>
						{subtitle && (
							<p className="mt-0.5 truncate text-[11px] font-medium text-muted">
								{subtitle}
							</p>
						)}
					</div>
				</div>
				<span className="shrink-0 whitespace-nowrap text-right tabular-nums text-sm font-black text-ink">
					{formatAmount(transaction.amount)} {vi.common.currency}
				</span>
			</div>
		);
	}

	const text =
		transaction.type === "income"
			? t(from.id === myMemberId ? vi.feed.incomeYou : vi.feed.income, {
					name: from.name,
					description: transaction.description,
					amount,
				})
			: "";
	return (
		<div
			className={`mx-auto flex max-w-full flex-wrap items-center gap-2 rounded-[18px] bg-sunken py-1.5 pl-2 pr-3 text-xs font-semibold ${uncounted ? "opacity-85" : ""}`}
		>
			<MemberShape {...from} size={18} />
			<span>{text}</span>
			{approvalStatus === "pending" && (
				<span className="rounded-[10px] bg-accent px-2 py-0.5 text-[11px] font-bold text-on-accent">
					{vi.approval.pendingTag}
				</span>
			)}
			{approvalStatus === "rejected" && (
				<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[11px] font-bold text-on-accent">
					{vi.approval.rejectedTag}
				</span>
			)}
			{transaction.dispute !== null && (
				<span className="rounded-[10px] bg-coral px-2 py-0.5 text-[11px] font-bold text-on-accent">
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
	);
}
