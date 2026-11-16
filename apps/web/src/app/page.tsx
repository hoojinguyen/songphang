"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState } from "react";
import { FeaturedGroupCard } from "../components/groups/FeaturedGroupCard";
import { GroupCard } from "../components/groups/GroupCard";
import { Button } from "../components/ui/Button";
import { Icon } from "../components/ui/Icon";
import { LoadError } from "../components/ui/LoadError";
import { MemberShape } from "../components/ui/MemberShape";
import { VerifyEmailBanner } from "../components/ui/VerifyEmailBanner";
import { useGroups } from "../lib/groups";
import { useMe } from "../lib/session";
import { useSessionGuard } from "../lib/use-session-guard";
import { t, vi } from "../messages/vi";

function GroupsSkeleton() {
	return (
		<main
			aria-busy="true"
			className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-6 px-5 py-6"
		>
			<div className="h-16 rounded-card bg-sunken" />
			<div className="my-auto h-32 rounded-card bg-sunken" />
			<div className="h-control-lg rounded-pill bg-sunken" />
		</main>
	);
}
function GroupsHeader({ name }: { name: string }) {
	return (
		<header className="flex items-center justify-between gap-4">
			<div>
				<p className="text-sm text-muted">{t(vi.groups.greeting, { name })}</p>
				<h1 className="text-title font-black">{vi.groups.title}</h1>
			</div>
			<Link
				href="/account"
				aria-label={vi.account.title}
				className="shrink-0 rounded-pill focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink"
			>
				<MemberShape shape="circle" color="mint" size={52} name={name} />
			</Link>
		</header>
	);
}
function GroupsContent({ name }: { name: string }) {
	const me = useMe();
	const groups = useGroups();
	const client = useQueryClient();
	const [deleted] = useState(
		() => client.getQueryData(["notice", "deleted"]) === true,
	);
	const [removed] = useState(
		() => client.getQueryData(["notice", "removed"]) === true,
	);
	useEffect(() => {
		client.removeQueries({ queryKey: ["notice", "removed"] });
		client.removeQueries({ queryKey: ["notice", "deleted"] });
	}, [client]);
	useSessionGuard(groups.error);
	return (
		<main className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col px-5 pb-5 pt-6">
			<GroupsHeader name={name} />
			{removed && <p role="status">{vi.common.removed}</p>}
			{deleted && <p role="status">{vi.groups.deleted}</p>}
			<div className="flex flex-1 flex-col gap-4 py-6">
				{groups.isPending ? (
					<div aria-busy="true" className="h-56 rounded-[40px] bg-sunken" />
				) : groups.isError ? (
					<LoadError
						isRetrying={groups.isFetching}
						onRetry={() => {
							void groups.refetch();
						}}
					/>
				) : groups.data.length === 0 ? (
					<div className="my-auto py-12 text-center">
						<h2 className="text-xl font-extrabold">{vi.groups.emptyTitle}</h2>
						<p className="mt-3 text-muted">{vi.groups.emptyHint}</p>
					</div>
				) : (
					groups.data.map((group, index) =>
						index === 0 ? (
							<FeaturedGroupCard key={group.id} group={group} />
						) : (
							<GroupCard key={group.id} group={group} />
						),
					)
				)}
			</div>
			{me.data?.emailVerified === false ? (
				<VerifyEmailBanner />
			) : (
				<Link
					href="/groups/new"
					className="flex h-control-lg items-center justify-center gap-2 rounded-pill bg-ink font-bold text-surface"
				>
					<Icon name="plus" size={24} />
					{vi.groups.create}
				</Link>
			)}
		</main>
	);
}
export default function GroupsPage() {
	const me = useMe();
	useSessionGuard(me.error);
	if (me.isPending || me.error?.status === 401) return <GroupsSkeleton />;
	if (me.isError)
		return (
			<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col items-center justify-center gap-4 px-5 text-center">
				<p role="alert">{vi.common.loadError}</p>
				<Button
					variant="primary"
					onClick={() => {
						void me.refetch();
					}}
					disabled={me.isFetching}
				>
					{vi.common.retry}
				</Button>
			</main>
		);
	return <GroupsContent name={me.data.name} />;
}
