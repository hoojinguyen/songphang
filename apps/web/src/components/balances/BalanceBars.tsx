import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { formatSignedAmount } from "../../lib/money";
import { vi } from "../../messages/vi";

const COLORS: Record<MemberDto["color"], string> = {
	mint: "bg-mint",
	sky: "bg-sky",
	coral: "bg-coral",
	lilac: "bg-lilac",
	sun: "bg-accent",
};
export function BalanceBars({
	balances,
	members,
}: {
	balances: BalancesResponse["balances"];
	members: MemberDto[];
}) {
	const largest = Math.max(
		1,
		...balances.map((balance) => Math.abs(balance.balance)),
	);
	const ordered = balances.toSorted((first, second) =>
		first.balance === second.balance
			? 0
			: first.balance < second.balance
				? 1
				: -1,
	);
	return (
		<section className="grid gap-4 rounded-[30px] bg-surface p-5">
			<h2 className="text-sm font-extrabold">
				{vi.balances.groupBalanceTitle}
			</h2>
			{ordered.map((balance) => {
				const member = members.find((member) => member.id === balance.memberId);
				if (!member || (!member.active && balance.balance === 0)) return null;
				const width = (Math.abs(balance.balance) / largest) * 50;
				return (
					<div key={member.id}>
						<div className="mb-1 flex justify-between gap-2 text-[13px]">
							<span className="min-w-0 break-words">
								{member.name}
								{!member.active && (
									<span className="ml-1 text-xs text-muted">
										{vi.balances.inactiveTag}
									</span>
								)}
							</span>
							<span className="shrink-0 font-bold">
								{formatSignedAmount(balance.balance)}
							</span>
						</div>
						<div className="relative h-[14px] rounded-pill bg-sunken">
							<span
								className={`absolute top-0 h-full rounded-pill ${COLORS[member.color]}`}
								style={{
									width: `${width}%`,
									left: balance.balance >= 0 ? "50%" : `${50 - width}%`,
								}}
							/>
						</div>
					</div>
				);
			})}
		</section>
	);
}
