"use client";
import type {
	CategoryDto,
	MemberDto,
	StatsResponse,
} from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { buildFilterQueryString } from "../../lib/transactions";
import { vi } from "../../messages/vi";
import { BarRow } from "./BarRow";
import { MemberStatsRow } from "./MemberStatsRow";

function formatBucketLabel(
	start: string,
	bucket: StatsResponse["bucket"],
): string {
	const [year, month, day] = start.split("-");
	if (bucket === "month") return `${month}/${year}`;
	return `${day}/${month}`;
}

function bucketRange(
	start: string,
	bucket: StatsResponse["bucket"],
): { from: string; to: string } {
	if (bucket === "day") return { from: start, to: start };
	const [year, month, day] = start.split("-").map(Number);
	if (bucket === "week" && year && month && day) {
		const end = new Date(Date.UTC(year, month - 1, day + 6))
			.toISOString()
			.slice(0, 10);
		return { from: start, to: end };
	}
	if (bucket === "month" && year && month) {
		const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
		return {
			from: start,
			to: `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`,
		};
	}
	return { from: start, to: start };
}

export function StatsContent({
	groupId,
	stats,
	members,
	categories,
	periodRange,
}: {
	groupId: string;
	stats: StatsResponse;
	members: MemberDto[];
	categories: CategoryDto[];
	periodRange: { from?: string; to?: string };
}) {
	const isEmpty = stats.byBucket.length === 0 && stats.byCategory.length === 0;
	const maxCategory = Math.max(
		0,
		...stats.byCategory.map((entry) => Math.max(0, entry.amount)),
	);
	const maxMember = Math.max(
		0,
		...stats.byMember.flatMap((entry) => [
			Math.max(0, entry.paid),
			Math.max(0, entry.share),
		]),
	);
	const maxBucket = Math.max(
		0,
		...stats.byBucket.map((entry) => Math.max(0, entry.amount)),
	);

	function feedHref(extra: Parameters<typeof buildFilterQueryString>[0]) {
		const qs = buildFilterQueryString({ ...periodRange, ...extra });
		return `/g/${encodeURIComponent(groupId)}${qs ? `?${qs}` : ""}`;
	}

	return (
		<div className="grid gap-5">
			<section className="rounded-card bg-accent p-5">
				<p className="text-[40px] font-black tracking-tight text-ink">
					{formatMoney(stats.total)}
				</p>
			</section>
			{isEmpty ? (
				<section className="rounded-card bg-surface p-6 text-center">
					<p className="text-sm font-semibold text-muted">{vi.stats.empty}</p>
				</section>
			) : (
				<>
					<section className="grid gap-1 rounded-card bg-surface p-4">
						<h2 className="px-2 pb-1 text-sm font-extrabold">
							{vi.stats.byCategory}
						</h2>
						{stats.byCategory.map((entry) => {
							const custom = entry.categoryId
								? categories.find((c) => c.id === entry.categoryId)
								: undefined;
							const label = entry.category
								? vi.expenseForm.categories[entry.category]
								: (custom?.name ?? vi.stats.uncategorised);
							const color = custom ? custom.color : "ink";
							return (
								<BarRow
									key={`${entry.category ?? "none"}-${entry.categoryId ?? "none"}`}
									label={label}
									amount={entry.amount}
									maxAmount={maxCategory}
									color={color}
									href={feedHref({
										...(entry.category ? { category: entry.category } : {}),
										...(entry.categoryId
											? { categoryId: entry.categoryId }
											: {}),
									})}
								/>
							);
						})}
					</section>
					<section className="grid gap-1 rounded-card bg-surface p-4">
						<h2 className="px-2 pb-1 text-sm font-extrabold">
							{vi.stats.byMember}
						</h2>
						{stats.byMember.map((entry) => {
							const member = members.find((m) => m.id === entry.memberId);
							if (!member) return null;
							return (
								<MemberStatsRow
									key={entry.memberId}
									name={member.name}
									paid={entry.paid}
									share={entry.share}
									maxAmount={maxMember}
									href={feedHref({ memberId: entry.memberId })}
								/>
							);
						})}
					</section>
					<section className="grid gap-1 rounded-card bg-surface p-4">
						<h2 className="px-2 pb-1 text-sm font-extrabold">
							{vi.stats.byTime}
						</h2>
						{stats.byBucket.map((entry) => (
							<BarRow
								key={entry.start}
								label={formatBucketLabel(entry.start, stats.bucket)}
								amount={entry.amount}
								maxAmount={maxBucket}
								color="sky"
								href={feedHref(bucketRange(entry.start, stats.bucket))}
							/>
						))}
					</section>
				</>
			)}
		</div>
	);
}
