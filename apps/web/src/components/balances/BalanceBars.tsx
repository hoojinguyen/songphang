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
	onInspectMember,
}: {
	balances: BalancesResponse["balances"];
	members: MemberDto[];
	onInspectMember?: (memberId: string) => void;
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
				const content = (
					<>
						<div className="mb-1 flex justify-between gap-2 text-[13px]">
							<span className="min-w-0 break-words">
								{member.name}
								{!member.active && (
									<span className="ml-1 text-xs text-muted">
										{vi.balances.inactiveTag}
									</span>
								)}
							</span>
							<span className="shrink-0 tabular-nums font-bold">
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
					</>
				);
				if (onInspectMember && member.kind === "person") {
					return (
						<button
							key={member.id}
							type="button"
							onClick={() => onInspectMember(member.id)}
							className="min-h-11 w-full rounded-[14px] text-left transition-colors hover:bg-sunken/50"
						>
							{content}
						</button>
					);
				}
				return <div key={member.id}>{content}</div>;
			})}
		</section>
	);
}
