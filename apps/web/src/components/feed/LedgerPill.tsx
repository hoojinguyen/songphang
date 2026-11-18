import type { MemberDto, TransactionListItemDto } from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
export function LedgerPill({
	transaction,
	members,
	myMemberId,
}: {
	transaction: TransactionListItemDto;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const from = members.find((m) => m.id === transaction.payers[0]?.memberId);
	const to = members.find((m) => m.id === transaction.shares[0]?.memberId);
	if (!from) return null;
	const amount = formatMoney(transaction.amount);
	const text =
		transaction.type === "income"
			? t(from.id === myMemberId ? vi.feed.incomeYou : vi.feed.income, {
					name: from.name,
					description: transaction.description,
					amount,
				})
			: to
				? from.id === myMemberId
					? t(vi.feed.transferFromYou, { name: to.name, amount })
					: to.id === myMemberId
						? t(vi.feed.transferToYou, { name: from.name, amount })
						: t(vi.feed.transferOther, { from: from.name, to: to.name, amount })
				: "";
	const approvalStatus = transaction.approval.status;
	const uncounted =
		approvalStatus === "pending" || approvalStatus === "rejected";
	return (
		<div
			className={`mx-auto flex max-w-full flex-wrap items-center gap-2 rounded-[18px] bg-sunken py-1.5 pl-2 pr-3 text-xs font-semibold ${uncounted ? "opacity-85" : ""}`}
		>
			<MemberShape {...from} size={18} />
			<span>{text}</span>
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
	);
}
