import type { MemberDto } from "@songphang/contract";
import { formatAmount } from "../../lib/money";
import { MemberShape } from "../ui/MemberShape";
export function ShareShapes({
	shares,
}: {
	shares: Array<{ member: MemberDto; amount: number }>;
}) {
	const total = shares.reduce((sum, s) => sum + s.amount, 0);
	return (
		<div className="flex flex-wrap items-end justify-center gap-3 rounded-[30px] bg-bg p-4">
			{shares.map(({ member, amount }) => (
				<div key={member.id} className="grid justify-items-center gap-2">
					<div
						className="share-shape"
						style={{
							height:
								56 +
								(total ? Number((BigInt(amount) * 48n) / BigInt(total)) : 0),
							width:
								56 +
								(total ? Number((BigInt(amount) * 48n) / BigInt(total)) : 0),
						}}
					>
						<MemberShape
							{...member}
							size={
								56 +
								(total ? Number((BigInt(amount) * 48n) / BigInt(total)) : 0)
							}
						/>
					</div>
					<span className="text-[13px] font-bold">{member.name}</span>
					<span className="text-[13px] font-extrabold">
						{formatAmount(amount)}
					</span>
				</div>
			))}
		</div>
	);
}
