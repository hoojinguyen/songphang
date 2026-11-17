"use client";
import {
	currentMonthRange,
	isWithinFiveYears,
	previousMonthRange,
} from "@songphang/core";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import {
	PeriodChips,
	type StatsPeriod,
} from "../../../../components/stats/PeriodChips";
import { StatsContent } from "../../../../components/stats/StatsContent";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { useCategories } from "../../../../lib/categories";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useMe } from "../../../../lib/session";
import { useGroupStats } from "../../../../lib/stats";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";

export default function StatsPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const [period, setPeriod] = useState<StatsPeriod>("all");
	const [customFrom, setCustomFrom] = useState(
		() => currentMonthRange(new Date()).start,
	);
	const [customTo, setCustomTo] = useState(
		() => currentMonthRange(new Date()).end,
	);
	const range =
		period === "all"
			? {}
			: period === "thisMonth"
				? (() => {
						const r = currentMonthRange(new Date());
						return { from: r.start, to: r.end };
					})()
				: period === "lastMonth"
					? (() => {
							const r = previousMonthRange(new Date());
							return { from: r.start, to: r.end };
						})()
					: isWithinFiveYears(customFrom, customTo)
						? { from: customFrom, to: customTo }
						: {};

	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const categories = useCategories(groupId);
	const stats = useGroupStats(groupId, range);
	const error =
		group.error ?? members.error ?? categories.error ?? stats.error ?? me.error;
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
		me.isPending ||
		group.isPending ||
		members.isPending ||
		categories.isPending ||
		stats.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-28 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(categories.isError && !categories.data) ||
		(stats.isError && !stats.data)
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
						void members.refetch();
						void categories.refetch();
						void stats.refetch();
					}}
					isRetrying={
						group.isFetching ||
						members.isFetching ||
						categories.isFetching ||
						stats.isFetching
					}
				/>
			</main>
		);

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6">
			<ScreenHeader
				title={vi.stats.title}
				subtitle={group.data.name}
				backHref={`/g/${encodeURIComponent(groupId)}`}
				backLabel={vi.common.back}
			/>
			<PeriodChips
				period={period}
				from={customFrom}
				to={customTo}
				onPeriod={setPeriod}
				onCustomFrom={setCustomFrom}
				onCustomTo={setCustomTo}
			/>
			<StatsContent
				groupId={groupId}
				stats={stats.data}
				members={members.data}
				categories={categories.data}
				periodRange={range}
			/>
		</main>
	);
}
