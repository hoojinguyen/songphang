"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { AddMemberRow } from "../../../../components/members/AddMemberRow";
import { MemberEditor } from "../../../../components/members/MemberEditor";
import { MemberRow } from "../../../../components/members/MemberRow";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";
export default function MembersPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const [expanded, setExpanded] = useState<string | null>(null);
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const error = group.error ?? members.error ?? balances.error;
	useSessionGuard(error);
	if (error?.status === 404)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/" className="flex min-h-11 items-center justify-center">
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	if (
		group.isPending ||
		members.isPending ||
		balances.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-80 rounded-card bg-sunken" />
			</main>
		);
	if (group.isError || members.isError || balances.isError)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void group.refetch();
						void members.refetch();
						void balances.refetch();
					}}
					isRetrying={
						group.isFetching || members.isFetching || balances.isFetching
					}
				/>
			</main>
		);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-6">
			<ScreenHeader
				title={group.data.name}
				subtitle={t(vi.members.memberCount, {
					count: String(members.data.length),
				})}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.back}
			/>
			{members.data.map((member) => (
				<div key={member.id} className="grid gap-2">
					<MemberRow
						member={member}
						isOwner={group.data.role === "owner"}
						isExpanded={expanded === member.id}
						onEdit={() =>
							setExpanded(expanded === member.id ? null : member.id)
						}
					/>
					{expanded === member.id && (
						<MemberEditor
							groupId={groupId}
							member={member}
							balance={
								balances.data.balances.find(
									(balance) => balance.memberId === member.id,
								)?.balance ?? 0
							}
						/>
					)}
				</div>
			))}
			<AddMemberRow groupId={groupId} members={members.data} />
			{group.data.role === "owner" && (
				<Link
					href={`/g/${groupId}/settings`}
					className="flex h-[60px] items-center justify-center rounded-[30px] bg-surface font-bold"
				>
					{vi.members.settingsLink}
				</Link>
			)}
		</main>
	);
}
