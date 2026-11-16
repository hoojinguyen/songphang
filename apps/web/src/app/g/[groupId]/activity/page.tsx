"use client";
import { useParams } from "next/navigation";
import { Fragment, useEffect, useRef } from "react";
import { ActivityRow } from "../../../../components/activity/ActivityRow";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { useActivity } from "../../../../lib/activity";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useMe } from "../../../../lib/session";
import { dayLabel } from "../../../../lib/transactions";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";
export default function ActivityPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const me = useMe();
	const query = useActivity(groupId);
	const target = useRef<HTMLDivElement>(null);
	const error = group.error ?? members.error ?? query.error;
	useSessionGuard(error);
	const entries = query.data?.pages.flatMap((p) => p.activity) ?? [];
	useEffect(() => {
		const element = target.current;
		if (!element) return;
		const observer = new IntersectionObserver((rows) => {
			if (
				rows.some((r) => r.isIntersecting) &&
				query.hasNextPage &&
				!query.isFetchingNextPage
			)
				void query.fetchNextPage();
		});
		observer.observe(element);
		return () => observer.disconnect();
	}, [query.hasNextPage, query.isFetchingNextPage, query.fetchNextPage]);
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-4 p-5">
			<ScreenHeader
				title={vi.activity.title}
				subtitle={group.data?.name ?? ""}
				backHref={`/g/${groupId}/members`}
				backLabel={vi.common.back}
			/>
			<h2 className="text-[30px] font-black">{vi.activity.headline}</h2>
			{error?.status === 404 ? (
				<p>{vi.common.groupNotFound}</p>
			) : !query.data &&
				(query.isPending || members.isPending || group.isPending) ? (
				<div aria-busy="true" className="h-96 rounded-card bg-sunken" />
			) : error && !query.data ? (
				<LoadError
					onRetry={() => {
						void query.refetch();
						void members.refetch();
						void group.refetch();
					}}
					isRetrying={query.isFetching}
				/>
			) : entries.length === 0 ? (
				<p>{vi.activity.empty}</p>
			) : (
				entries.map((entry, index) => {
					const label = dayLabel(entry.createdAt, new Date());
					const previous = entries[index - 1];
					return (
						<Fragment key={entry.id}>
							{(!previous ||
								dayLabel(previous.createdAt, new Date()) !== label) && (
								<p className="text-center text-xs font-semibold text-muted">
									{label}
								</p>
							)}
							<ActivityRow
								entry={entry}
								members={members.data ?? []}
								groupId={groupId}
								canRestore={
									group.data?.role !== "viewer" &&
									me.data?.emailVerified === true
								}
							/>
						</Fragment>
					);
				})
			)}
			<div ref={target} className="h-px" />
			{query.isFetchingNextPage && <p>{vi.activity.loadingOlder}</p>}
			{query.isFetchNextPageError && (
				<LoadError
					onRetry={() => {
						void query.fetchNextPage();
					}}
					isRetrying={query.isFetchingNextPage}
				/>
			)}
		</main>
	);
}
