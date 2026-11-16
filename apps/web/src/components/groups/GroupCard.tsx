import type { GroupSummaryDto } from "@songphang/contract";
import Link from "next/link";
import { formatSignedAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function GroupCard({ group }: { group: GroupSummaryDto }) {
	const tone =
		group.myBalance > 0
			? "bg-accent"
			: group.myBalance < 0
				? "bg-debt-soft"
				: "bg-sunken";
	const caption =
		group.myBalance > 0
			? vi.groups.chipOwedToYou
			: group.myBalance < 0
				? vi.groups.chipYouOwe
				: vi.groups.chipSettled;
	return (
		<Link
			href={`/g/${group.id}`}
			className="flex flex-wrap items-center justify-between gap-3 rounded-[32px] bg-surface px-5 py-[18px]"
		>
			<div className="min-w-0">
				<div className="flex flex-wrap items-center gap-1">
					{group.previewMembers.map((member) => (
						<MemberShape key={member.id} {...member} size={22} />
					))}
					{group.memberCount > 4 && (
						<span>
							{t(vi.groups.moreMembers, {
								count: String(group.memberCount - 4),
							})}
						</span>
					)}
				</div>
				<h2 className="break-words text-[18px] font-extrabold">{group.name}</h2>
				<p className="text-[13px] text-muted">
					{t(vi.groups.memberCount, { count: String(group.memberCount) })}
				</p>
			</div>
			<div className={`shrink-0 rounded-[18px] px-3 py-2 text-right ${tone}`}>
				<p className="break-words text-[18px] font-black">
					{formatSignedAmount(group.myBalance)}
				</p>
				<p className="text-[11px] font-bold">{caption}</p>
			</div>
		</Link>
	);
}
