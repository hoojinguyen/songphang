"use client";
import type { ActivityDto, MemberDto } from "@songphang/contract";
import { describeActivity } from "../../lib/activity-sentences";
import { useRestoreTransaction } from "../../lib/transaction-changes";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { MemberShape } from "../ui/MemberShape";
import { useSnackbar } from "../ui/Snackbar";
import { ChangeChips } from "./ChangeChips";
export function ActivityRow({
	entry,
	members,
	groupId,
	canRestore,
}: {
	entry: ActivityDto;
	members: MemberDto[];
	groupId: string;
	canRestore: boolean;
}) {
	const restore = useRestoreTransaction(groupId);
	const snackbar = useSnackbar();
	const member = members.find((m) => m.id === entry.actor?.memberId);
	const description = describeActivity(entry, members);
	return (
		<article className="flex gap-3 rounded-[26px] bg-surface px-[14px] py-3">
			{member ? (
				<MemberShape {...member} size={40} />
			) : (
				<span className="size-10 shrink-0 rounded-full bg-sunken" />
			)}
			<div className="grid min-w-0 flex-1 gap-2">
				<p className="break-words text-sm leading-[1.45]">
					{description.parts.map((part) =>
						part.bold ? (
							<strong key={part.key} className="font-extrabold">
								{part.text}
							</strong>
						) : (
							part.text
						),
					)}
				</p>
				<ChangeChips chips={description.chips} />
				{entry.canRestore && canRestore && entry.entityId && (
					<Button
						variant="primary"
						className="h-11"
						disabled={restore.isPending}
						onClick={() => {
							if (entry.entityId)
								restore.mutate(entry.entityId, {
									onSuccess: () => snackbar({ text: vi.expenseForm.restored }),
								});
						}}
					>
						{vi.activity.restoreButton}
					</Button>
				)}
				{restore.isError && <p role="alert">{vi.common.saveError}</p>}
				<time className="text-xs text-muted" dateTime={entry.createdAt}>
					{new Date(entry.createdAt).toLocaleTimeString("vi-VN", {
						hour: "2-digit",
						minute: "2-digit",
					})}
				</time>
			</div>
		</article>
	);
}
