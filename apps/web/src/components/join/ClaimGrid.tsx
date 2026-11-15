import type { InvitePreviewResponse } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function normalizeMemberName(name: string) {
	return name
		.normalize("NFD")
		.replace(/\p{M}/gu, "")
		.replace(/[đĐ]/g, "d")
		.trim()
		.toLocaleLowerCase("vi");
}
export function ClaimGrid({
	members,
	accountName,
	selected,
	onSelect,
}: {
	members: InvitePreviewResponse["members"];
	accountName: string;
	selected: string | null;
	onSelect: (id: string) => void;
}) {
	return (
		<div className="grid grid-cols-2 gap-2.5">
			{members.map((member) => (
				<button
					key={member.id}
					type="button"
					aria-pressed={selected === member.id}
					disabled={member.claimed}
					onClick={() => onSelect(member.id)}
					className={`grid justify-items-center gap-2 rounded-[36px] border-[3px] p-4 ${selected === member.id ? "border-ink" : "border-transparent"} ${member.claimed ? "bg-sunken" : "bg-surface"}`}
				>
					<span className={member.claimed ? "opacity-55" : ""}>
						<MemberShape {...member} size={84} />
					</span>
					<span className="text-base font-extrabold">{member.name}</span>
					<span className="text-xs text-muted">
						{member.claimed
							? vi.join.claimed
							: normalizeMemberName(member.name) ===
									normalizeMemberName(accountName)
								? vi.join.sameName
								: vi.join.unclaimed}
					</span>
				</button>
			))}
		</div>
	);
}
