import type { GroupSummaryDto } from "@songphang/contract";
import Link from "next/link";
import { formatSignedAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function FeaturedGroupCard({ group }: { group: GroupSummaryDto }) {
	const isArchived = Boolean(group.archivedAt);
	const caption =
		group.myBalance > 0
			? vi.groups.owedToYou
			: group.myBalance < 0
				? vi.groups.youOwe
				: vi.groups.settled;
	return (
		<Link
			href={`/g/${group.id}`}
			className="block rounded-[40px] bg-accent px-[22px] py-5 text-on-accent"
		>
			<div className="mb-3 flex items-center justify-between">
				<div className="flex gap-1">
					{group.previewMembers.map((member) => (
						<MemberShape key={member.id} {...member} size={30} />
					))}
				</div>
				<div className="flex items-center gap-1.5">
					{isArchived && (
						<span className="rounded-pill bg-bg/20 px-2 py-0.5 text-xs font-bold text-on-accent">
							{vi.groups.tabArchived}
						</span>
					)}
					{Boolean(
						group.pendingActionCount && group.pendingActionCount > 0,
					) && (
						<span className="rounded-pill bg-coral px-2 py-0.5 text-xs font-extrabold text-on-accent">
							{vi.groups.needsAction}
						</span>
					)}
				</div>
			</div>
			<h2 className="break-words text-xl font-extrabold">{group.name}</h2>
			<p className="tabular-nums break-words text-[52px] font-black tracking-tight">
				{formatSignedAmount(group.myBalance)}
			</p>
			<p className="text-sm font-semibold">
				{group.householdName ? `${group.householdName} · ${caption}` : caption}
			</p>
			{group.householdName && group.myIndividualBalance !== undefined && (
				<p className="mt-1 tabular-nums text-xs font-semibold opacity-80">
					{t(vi.households.personalShareTemplate, {
						amount: `${formatSignedAmount(group.myIndividualBalance)} ${vi.common.currency}`,
					})}
				</p>
			)}
		</Link>
	);
}
