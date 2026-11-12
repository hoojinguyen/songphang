import type { MemberDto } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function MemberRow({
	member,
	isOwner,
	isExpanded,
	onEdit,
}: {
	member: MemberDto;
	isOwner: boolean;
	isExpanded: boolean;
	onEdit: () => void;
}) {
	return (
		<button
			type="button"
			aria-label={t(vi.members.edit, { name: member.name })}
			aria-expanded={isExpanded}
			onClick={onEdit}
			className={`flex w-full items-center gap-3 rounded-[28px] bg-surface p-4 text-left ${member.active ? "text-ink" : "text-muted"}`}
		>
			<MemberShape {...member} size={52} />
			<span className="min-w-0 flex-1">
				<span className="block break-words text-base font-extrabold">
					{member.name}
				</span>
				<span className="text-xs text-muted">
					{member.isMe
						? vi.members.youTag
						: !member.active
							? vi.members.inactiveTag
							: ""}
				</span>
			</span>
			{member.isMe && isOwner && (
				<span className="rounded-[14px] bg-accent px-3 py-1 text-xs text-ink">
					{vi.members.ownerBadge}
				</span>
			)}
		</button>
	);
}
