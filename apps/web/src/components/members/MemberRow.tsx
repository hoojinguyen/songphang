import type { GroupRole, HouseholdDto, MemberDto } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function MemberRow({
	member,
	role,
	household,
	isExpanded,
	onEdit,
	canEdit = true,
}: {
	member: MemberDto;
	role: GroupRole | undefined;
	household?: HouseholdDto | undefined;
	isExpanded: boolean;
	onEdit: () => void;
	canEdit?: boolean;
}) {
	const RowTag = canEdit ? "button" : "div";
	const isRep = household?.representativeMemberId === member.id;
	return (
		<RowTag
			type={canEdit ? "button" : undefined}
			aria-label={
				canEdit ? t(vi.members.edit, { name: member.name }) : member.name
			}
			aria-expanded={canEdit ? isExpanded : undefined}
			onClick={canEdit ? onEdit : undefined}
			className={`flex w-full items-center gap-3 rounded-[28px] bg-surface p-4 text-left ${member.active ? "text-ink" : "text-muted"}`}
		>
			<MemberShape {...member} size={52} />
			<span className="min-w-0 flex-1">
				<span className="block break-words text-base font-extrabold">
					{member.name}
				</span>
				<span className="flex flex-wrap items-center gap-1.5 text-xs text-muted">
					<span>
						{!member.active
							? vi.members.inactiveTag
							: member.isMe
								? vi.members.loggedInYou
								: member.claimed
									? vi.members.joined
									: vi.members.unclaimed}
					</span>
					{household && (
						<span className="rounded-pill bg-sunken px-2 py-0.5 text-[11px] font-bold text-ink">
							{isRep
								? t(vi.households.representativeBadge, {
										name: household.name,
									})
								: household.name}
						</span>
					)}
				</span>
			</span>
			{role && (
				<span
					className={`rounded-[14px] px-3 py-1 text-xs ${role === "owner" ? "bg-accent font-bold text-on-accent" : "bg-sunken text-ink"}`}
				>
					{role === "owner"
						? vi.members.ownerBadge
						: role === "editor"
							? vi.members.roleEditor
							: vi.members.roleViewer}
				</span>
			)}
		</RowTag>
	);
}
