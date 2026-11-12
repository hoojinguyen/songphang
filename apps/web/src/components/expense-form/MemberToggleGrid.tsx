import type { MemberDto } from "@songphang/contract";
import { MemberShape } from "../ui/MemberShape";
export function MemberToggleGrid({
	members,
	selectedIds,
	onToggle,
	captionFor,
	label,
}: {
	members: MemberDto[];
	selectedIds: readonly string[];
	onToggle: (memberId: string) => void;
	captionFor: (member: MemberDto) => string;
	label: string;
}) {
	return (
		<fieldset aria-label={label} className="grid min-w-0 grid-cols-4 gap-1">
			{members.map((member) => (
				<button
					key={member.id}
					type="button"
					aria-label={member.name}
					aria-pressed={selectedIds.includes(member.id)}
					onClick={() => onToggle(member.id)}
					className={`flex min-h-11 min-w-0 flex-col items-center rounded-[20px] border-[3px] px-1 py-2 ${selectedIds.includes(member.id) ? "border-ink bg-surface" : "border-transparent bg-bg text-muted"}`}
				>
					<MemberShape {...member} size={44} />
					<span className="max-w-full break-words text-xs">
						{captionFor(member)}
					</span>
				</button>
			))}
		</fieldset>
	);
}
