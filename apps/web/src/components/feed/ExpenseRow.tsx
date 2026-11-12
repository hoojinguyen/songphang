import type { MemberDto, TransactionDto } from "@songphang/contract";
import { formatAmount, formatCompactAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function ExpenseRow({
	transaction,
	members,
	myMemberId,
}: {
	transaction: TransactionDto;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const payer = members.find(
		(member) => member.id === transaction.payers[0]?.memberId,
	);
	const isMine = payer?.id === myMemberId;
	const myShare = transaction.shares.find(
		(share) => share.memberId === myMemberId,
	);
	return (
		<div
			className={`flex items-end gap-2 ${isMine ? "justify-end" : "justify-start"}`}
		>
			{!isMine && payer && <MemberShape {...payer} size={36} />}
			<div
				className={`min-w-0 px-4 pb-[14px] pt-3 ${isMine ? "max-w-[300px] rounded-[26px] rounded-br-[8px] bg-ink text-surface" : "max-w-[270px] rounded-[26px] rounded-bl-[8px] bg-surface"}`}
			>
				<p
					className={`text-xs font-semibold ${isMine ? "text-on-ink-muted" : "text-muted"}`}
				>
					{isMine
						? vi.feed.youPaid
						: t(vi.feed.memberPaid, { name: payer?.name ?? "" })}
				</p>
				<div className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
					<p className="min-w-0 break-words text-[15px] font-bold">
						{transaction.description}
					</p>
					<p className="text-[19px] font-black">
						{formatAmount(transaction.amount)}
					</p>
				</div>
				{isMine ? (
					<div className="mt-2 flex flex-wrap gap-1">
						{transaction.shares.slice(0, 4).map((share) => {
							const member = members.find(
								(member) => member.id === share.memberId,
							);
							return (
								<span
									key={share.memberId}
									className="flex items-center gap-1 rounded-[14px] bg-ink-raised px-[9px] py-[5px] text-xs font-bold"
								>
									{member && <MemberShape {...member} size={14} />}
									<span>{formatCompactAmount(share.amount)}</span>
								</span>
							);
						})}
						{transaction.shares.length > 4 && (
							<span className="px-2 py-1 text-xs">
								{t(vi.feed.moreShares, {
									count: String(transaction.shares.length - 4),
								})}
							</span>
						)}
					</div>
				) : (
					<p className="mt-1 text-[13px] text-muted">
						{myShare
							? t(vi.feed.equalSplitMine, {
									count: String(transaction.shares.length),
									amount: formatAmount(myShare.amount),
								})
							: t(vi.feed.equalSplitNotMine, {
									count: String(transaction.shares.length),
								})}
					</p>
				)}
			</div>
		</div>
	);
}
