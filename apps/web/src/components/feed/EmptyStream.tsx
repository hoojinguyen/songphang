import type { MemberDto } from "@songphang/contract";
import Link from "next/link";
import { vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function EmptyStream({
	members,
	groupId,
	canInvite,
}: {
	members: MemberDto[];
	groupId: string;
	canInvite: boolean;
}) {
	return (
		<div className="min-h-0 flex-1 overflow-y-auto text-center">
			<div className="flex min-h-full flex-col items-center justify-center gap-4 py-6">
				<div className="flex justify-center gap-1">
					{members.slice(0, 4).map((member) => (
						<MemberShape key={member.id} {...member} size={76} />
					))}
				</div>
				<h2 className="text-[32px] font-black">{vi.feed.emptyTitle}</h2>
				<p className="text-sm text-muted">{vi.feed.emptyHint}</p>
				{canInvite && (
					<Link
						href={`/g/${groupId}/members`}
						className="flex min-h-11 items-center font-bold"
					>
						{vi.feed.inviteLink}
					</Link>
				)}
			</div>
		</div>
	);
}
