"use client";
import type { MemberDto } from "@songphang/contract";
import Link from "next/link";
import { useDraft } from "../../lib/draft-context";
import { vi } from "../../messages/vi";
import { HighlightedSentence } from "../quick-entry/HighlightedSentence";
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
	const memory = useDraft();
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
				{vi.feed.samples.map((sentence) => (
					<Link
						key={sentence}
						href={`/g/${groupId}/tx/new`}
						onClick={() => {
							memory.setSentence(sentence);
							memory.setDraft(null);
						}}
						className="rounded-[24px] bg-surface px-[18px] py-[14px] text-[15px] font-semibold"
					>
						<HighlightedSentence
							text={sentence}
							spans={[
								{
									start: sentence.search(/\d/),
									end:
										sentence.search(/\d/) +
										(sentence.match(/\d+k/)?.[0].length ?? 0),
									kind: "amount",
								},
							]}
						/>
					</Link>
				))}
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
