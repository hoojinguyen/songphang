import type { MemberDto, TransactionDto } from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function LedgerPill({
	transaction,
	members,
	myMemberId,
}: {
	transaction: TransactionDto;
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
	return (
		<div className="mx-auto flex max-w-full items-center gap-2 rounded-[18px] bg-sunken py-1.5 pl-2 pr-3 text-xs font-semibold">
			<MemberShape {...from} size={18} />
			<span>{text}</span>
			{transaction.version > 1 && (
				<span className="text-[11px] font-bold text-muted">
					{vi.feed.edited}
				</span>
			)}
		</div>
	);
}
