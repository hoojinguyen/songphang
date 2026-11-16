"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { AddMemberRow } from "../../../../components/members/AddMemberRow";
import { InviteCard } from "../../../../components/members/InviteCard";
import { LeaveGroupButton } from "../../../../components/members/LeaveGroupButton";
import { MemberEditor } from "../../../../components/members/MemberEditor";
import { MemberRow } from "../../../../components/members/MemberRow";
import { UserControls } from "../../../../components/members/UserControls";
import { Button } from "../../../../components/ui/Button";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { VerifyEmailBanner } from "../../../../components/ui/VerifyEmailBanner";
import { useBalances } from "../../../../lib/balances";
import { useGroupUserAction, useGroupUsers } from "../../../../lib/group-users";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";
export default function MembersPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const [expanded, setExpanded] = useState<string | null>(null);
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const users = useGroupUsers(groupId);
	const action = useGroupUserAction(groupId);
	const error =
		group.error ?? members.error ?? balances.error ?? users.error ?? me.error;
	useSessionGuard(action.error);
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
		users.isPending ||
		me.isPending ||
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
	if (
		users.isError ||
		me.isError ||
		group.isError ||
		members.isError ||
		balances.isError
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void users.refetch();
						void me.refetch();
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
						role={users.data.find((user) => user.memberId === member.id)?.role}
						canEdit={me.data.emailVerified && group.data.role !== "viewer"}
						isExpanded={expanded === member.id}
						onEdit={() =>
							setExpanded(expanded === member.id ? null : member.id)
						}
					/>
					{me.data.emailVerified &&
						group.data.role !== "viewer" &&
						expanded === member.id && (
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
					{me.data.emailVerified && member.active && !member.claimed && (
						<Button
							variant="surface"
							disabled={action.isPending}
							onClick={() =>
								action.mutate({ action: "choose", memberId: member.id })
							}
						>
							{vi.members.thisIsMe}
						</Button>
					)}
					{me.data.emailVerified &&
						group.data.role === "owner" &&
						users.data
							.filter((user) => user.memberId === member.id && !user.isMe)
							.map((user) => (
								<UserControls key={user.userId} groupId={groupId} user={user} />
							))}
				</div>
			))}
			{me.data.emailVerified && group.data.role !== "viewer" ? (
				<AddMemberRow groupId={groupId} members={members.data} />
			) : (
				<VerifyEmailBanner />
			)}
			{users.data
				.filter((user) => user.memberId === null)
				.map((user) => (
					<div
						key={user.userId}
						className="grid gap-3 rounded-[28px] bg-surface p-4"
					>
						<div className="flex items-center gap-3">
							<span className="size-[52px] rounded-full bg-sunken" />
							<div>
								<p className="font-extrabold">{user.name}</p>
								<p className="text-xs text-muted">{vi.members.noShape}</p>
							</div>
						</div>
						{me.data.emailVerified &&
							group.data.role === "owner" &&
							!user.isMe && <UserControls groupId={groupId} user={user} />}
					</div>
				))}
			{action.isError && (
				<p role="alert">
					{action.error.status === 403
						? vi.common.forbidden
						: action.error.code === "MEMBER_ALREADY_CLAIMED"
							? vi.join.claimedMeanwhile
							: vi.common.saveError}
				</p>
			)}
			{group.data.role !== "owner" && me.data.emailVerified && (
				<LeaveGroupButton groupId={groupId} name={group.data.name} />
			)}

			{group.data.role !== "viewer" && <InviteCard groupId={groupId} />}
			<div className="flex gap-3">
				<Link
					href={`/g/${groupId}/activity`}
					className="flex h-[60px] flex-1 items-center justify-center rounded-[30px] bg-surface font-bold"
				>
					{vi.activity.title}
				</Link>
				{group.data.role === "owner" && (
					<Link
						href={`/g/${groupId}/settings`}
						className="flex h-[60px] flex-1 items-center justify-center rounded-[30px] bg-surface font-bold"
					>
						{vi.members.settingsLink}
					</Link>
				)}
			</div>
		</main>
	);
}
