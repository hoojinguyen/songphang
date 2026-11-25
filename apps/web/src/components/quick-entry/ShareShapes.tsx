"use client";
import type { MemberDto } from "@songphang/contract";
import { formatAmount } from "../../lib/money";
import { MemberShape } from "../ui/MemberShape";

export function ShareShapes({
	shares,
}: {
	shares: Array<{ member: MemberDto; amount: number }>;
}) {
	const total = shares.reduce((sum, s) => sum + s.amount, 0);
	const dense = shares.length > 6;
	const baseSize = dense ? 36 : 48;
	const growth = dense ? 20n : 40n;

	return (
		<div className="max-h-[220px] overflow-y-auto rounded-[24px] bg-bg p-3">
			<div className="grid grid-cols-3 gap-2.5 sm:grid-cols-4">
				{shares.map(({ member, amount }) => {
					const shapeSize =
						baseSize +
						(total ? Number((BigInt(amount) * growth) / BigInt(total)) : 0);

					return (
						<div
							key={member.id}
							className="flex flex-col items-center justify-end gap-1 text-center"
						>
							<div
								className="share-shape flex items-center justify-center"
								style={{
									height: shapeSize,
									width: shapeSize,
								}}
							>
								<MemberShape {...member} size={shapeSize} />
							</div>
							<span className="max-w-[76px] truncate text-[11px] font-bold text-ink">
								{member.name}
							</span>
							<span className="max-w-[80px] truncate tabular-nums text-[11px] font-extrabold text-ink">
								{formatAmount(amount)}
							</span>
						</div>
					);
				})}
			</div>
		</div>
	);
}
