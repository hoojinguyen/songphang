import type { MemberDto } from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function AllSettled({
	groupId,
	members,
	myMemberId,
}: {
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
				{members.map((member) => (
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
			<Link
				href={`/g/${groupId}`}
				className="flex h-control-lg items-center justify-center rounded-pill bg-ink font-bold text-surface"
			>
				{vi.balances.backToGroup}
			</Link>
		</>
	);
}
