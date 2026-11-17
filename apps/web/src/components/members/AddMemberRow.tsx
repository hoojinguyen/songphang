"use client";
import type { MemberDto } from "@songphang/contract";
import { useState } from "react";
import { useCreateMember } from "../../lib/members";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { NewMemberRow } from "../groups/NewMemberRow";
import { OnlineButton } from "../ui/OnlineButton";

function OpenMemberRow({
	groupId,
	members,
	onClose,
}: {
	groupId: string;
	members: MemberDto[];
	onClose: () => void;
}) {
	const [key] = useState(() => crypto.randomUUID());
	const create = useCreateMember(groupId);
	useSessionGuard(create.error);
	return (
		<div className="grid gap-3">
			<NewMemberRow
				usedPairs={members.flatMap((member) =>
					member.shape === "fund" || member.color === "sun"
						? []
						: [{ shape: member.shape, color: member.color }],
				)}
				position={(members.at(-1)?.position ?? -1) + 1}
				onAdd={(name) =>
					create.mutate({ request: { name }, key }, { onSuccess: onClose })
				}
				disabled={create.isPending}
				label={vi.members.newNameLabel}
				addLabel={vi.members.add}
			/>
			{create.isError && <p role="alert">{vi.common.saveError}</p>}
		</div>
	);
}
export function AddMemberRow({
	groupId,
	members,
}: {
	groupId: string;
	members: MemberDto[];
}) {
	const [isOpen, setIsOpen] = useState(false);
	if (members.length >= 100)
		return <p className="text-sm text-muted">{vi.members.limitReached}</p>;
	if (isOpen)
		return (
			<OpenMemberRow
				groupId={groupId}
				members={members}
				onClose={() => setIsOpen(false)}
			/>
		);
	return (
		<OnlineButton
			type="button"
			onClick={() => setIsOpen(true)}
			className="h-14 w-full rounded-[28px] border-2 border-dashed border-[var(--color-dashed)] bg-transparent font-bold"
		>
			{vi.members.addName}
		</OnlineButton>
	);
}
