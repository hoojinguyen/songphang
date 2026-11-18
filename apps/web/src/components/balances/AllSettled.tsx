import type { MemberDto, TransactionListItemDto } from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function AllSettled({
	recorded,
	groupId,
	members,
	myMemberId,
}: {
	recorded: TransactionListItemDto[];
	groupId: string;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	return (
		<>
			<div className="rounded-[40px] bg-accent p-6">
				<h2 className="text-[48px] font-black leading-tight">
					{vi.balances.allSettledTitle}
				</h2>
				<p className="mt-3 text-[15px] font-semibold">
					{vi.balances.allSettledHint}
				</p>
			</div>
			<div className="grid grid-cols-2 gap-5 rounded-card bg-surface p-5">
				{members
					.filter((member) => member.kind === "person")
					.map((member) => (
						<div
							key={member.id}
							className="flex flex-col items-center gap-2 text-center"
						>
							<MemberShape {...member} size={72} />
							<p className="break-words font-bold">
								{member.id === myMemberId ? vi.common.you : member.name}
							</p>
							<p>{formatMoney(0)}</p>
						</div>
					))}
			</div>
			{recorded.length > 0 && (
				<section className="grid gap-3 rounded-[30px] bg-surface p-5">
					<h2 className="font-extrabold">
						{t(vi.balances.recordedTitle, { count: String(recorded.length) })}
					</h2>
					{recorded.slice(0, 5).map((transaction) => {
						const from = members.find(
							(m) => m.id === transaction.payers[0]?.memberId,
						);
						const to = members.find(
							(m) => m.id === transaction.shares[0]?.memberId,
						);
						if (!from || !to) return null;
						const text =
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
								key={transaction.id}
								className="flex items-center gap-2 text-xs"
							>
								<MemberShape {...from} size={28} />
								<span className="flex-1">{text}</span>
								<strong>{formatMoney(transaction.amount)}</strong>
							</div>
						);
					})}
				</section>
			)}

			<Link
				href={`/g/${groupId}`}
				className="flex h-control-lg items-center justify-center rounded-pill bg-ink font-bold text-surface"
			>
				{vi.balances.backToGroup}
			</Link>
		</>
	);
}
