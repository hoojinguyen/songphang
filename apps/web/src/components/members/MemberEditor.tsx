"use client";
import type { MemberDto } from "@songphang/contract";
import { useState } from "react";
import { useDeleteMember, useUpdateMember } from "../../lib/members";
import { formatSignedAmount } from "../../lib/money";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
export function MemberEditor({
	groupId,
	member,
	balance,
}: {
	groupId: string;
	member: MemberDto;
	balance: number;
}) {
	const [name, setName] = useState(member.name);
	const [showsWarning, setShowsWarning] = useState(false);
	const update = useUpdateMember(groupId);
	const remove = useDeleteMember(groupId);
	useSessionGuard(update.error ?? remove.error);
	const isPending = update.isPending || remove.isPending;
	const setActive = (active: boolean) =>
		update.mutate(
			{ memberId: member.id, request: { active } },
			{ onSuccess: () => setShowsWarning(false) },
		);
	const error =
		remove.error?.code === "MEMBER_HAS_TRANSACTIONS"
			? t(vi.members.hasTransactions, { name: member.name })
			: update.isError || remove.isError
				? vi.common.saveError
				: null;
	return (
		<div className="grid gap-3 rounded-[28px] bg-surface p-4">
			<label className="grid gap-1 text-xs text-muted">
				{vi.members.nameLabel}
				<input
					value={name}
					onChange={(event) => setName(event.target.value)}
					maxLength={50}
					className="h-12 min-w-0 rounded-[20px] bg-bg px-3 text-base text-ink"
				/>
			</label>
			<Button
				variant="primary"
				disabled={isPending || !name.trim() || name.trim() === member.name}
				onClick={() =>
					update.mutate({ memberId: member.id, request: { name: name.trim() } })
				}
			>
				{vi.members.saveName}
			</Button>
			{!member.isMe && (
				<>
					{showsWarning ? (
						<div className="grid gap-2">
							<p>
								{t(vi.members.deactivateWarning, {
									name: member.name,
									amount: `${formatSignedAmount(balance)} ${vi.common.currency}`,
								})}
							</p>
							<Button
								variant="primary"
								disabled={isPending}
								onClick={() => setActive(false)}
							>
								{vi.members.deactivateAnyway}
							</Button>
							<Button
								variant="surface"
								disabled={isPending}
								onClick={() => setShowsWarning(false)}
							>
								{vi.members.keepActive}
							</Button>
						</div>
					) : (
						<Button
							variant="surface"
							disabled={isPending}
							onClick={() => {
								if (member.active && balance !== 0) setShowsWarning(true);
								else setActive(!member.active);
							}}
						>
							{member.active ? vi.members.deactivate : vi.members.reactivate}
						</Button>
					)}
					<Button
						variant="surface"
						disabled={isPending}
						onClick={() => remove.mutate(member.id)}
					>
						{vi.members.delete}
					</Button>
				</>
			)}
			{error && <p role="alert">{error}</p>}
		</div>
	);
}
