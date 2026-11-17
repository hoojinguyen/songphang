"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { FundSettingsCard } from "../../../../components/fund/FundSettingsCard";
import { FundShape } from "../../../../components/ui/FundShape";
import { LoadError } from "../../../../components/ui/LoadError";
import { MemberShape } from "../../../../components/ui/MemberShape";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { formatMoney } from "../../../../lib/money";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";

export default function FundPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const error = group.error ?? members.error ?? balances.error ?? me.error;
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
		balances.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-44 rounded-card bg-sunken" />
				<div className="h-52 rounded-card bg-sunken" />
			</main>
		);
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(balances.isError && !balances.data)
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
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

	const fund = balances.data.fund;
	if (!fund)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<Link
					href={`/g/${groupId}/balances`}
					className="flex min-h-11 items-center justify-center font-bold"
				>
					{vi.common.back}
				</Link>
			</main>
		);

	const people = members.data.filter((m) => m.kind === "person");
	const holder = fund.holderMemberId
		? people.find((m) => m.id === fund.holderMemberId)
		: undefined;
	const canWrite = group.data.role !== "viewer" && me.data.emailVerified;

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6">
			<ScreenHeader
				title={fund.name}
				backHref={`/g/${groupId}/balances`}
				backLabel={vi.common.back}
			/>
			<section className="grid justify-items-center gap-2 rounded-[40px] bg-sun p-6 text-center text-ink">
				<FundShape name={fund.name} size={40} />
				<p className="text-xs font-bold">
					{fund.cash < 0 ? vi.fund.negativeLabel : vi.fund.remainingLabel}
				</p>
				<p className="text-[44px] font-black leading-none">
					{formatMoney(Math.abs(fund.cash))}
				</p>
				{holder && (
					<p className="text-xs font-bold">
						{t(vi.fund.holderLine, { name: holder.name })}
					</p>
				)}
				{!fund.active && (
					<p className="rounded-pill bg-surface/80 px-3 py-1 text-xs font-bold">
						{vi.fund.inactiveTag}
					</p>
				)}
			</section>
			{canWrite && fund.active && (
				<div className="flex gap-2">
					<Link
						href={`/g/${groupId}/tx/new?form=1&type=transfer&to=${encodeURIComponent(fund.memberId)}`}
						className="flex min-h-14 flex-1 items-center justify-center rounded-[28px] bg-ink px-4 text-sm font-extrabold text-surface"
					>
						{vi.fund.contributeButton}
					</Link>
					<Link
						href={`/g/${groupId}/tx/new?form=1&type=transfer&from=${encodeURIComponent(fund.memberId)}`}
						className="flex min-h-14 flex-1 items-center justify-center rounded-[28px] bg-surface px-4 text-sm font-extrabold text-ink"
					>
						{vi.fund.withdrawButton}
					</Link>
				</div>
			)}
			<section className="grid gap-3 rounded-[30px] bg-surface p-5">
				<h2 className="font-extrabold">{vi.fund.contributionsTitle}</h2>
				{fund.contributions.length === 0 ? (
					<p className="text-sm text-muted">{vi.fund.noContributions}</p>
				) : (
					fund.contributions.map((entry) => {
						const person = people.find((m) => m.id === entry.memberId);
						if (!person) return null;
						return (
							<div key={entry.memberId} className="flex items-center gap-3">
								<MemberShape {...person} size={32} />
								<span className="min-w-0 flex-1 break-words font-bold">
									{person.name}
								</span>
								<span className="shrink-0 font-black">
									{formatMoney(entry.amount)}
								</span>
							</div>
						);
					})
				)}
			</section>
			{canWrite && (
				<FundSettingsCard
					key={`${fund.name}-${fund.holderMemberId ?? "none"}-${fund.active}`}
					groupId={groupId}
					fund={fund}
					people={people}
				/>
			)}
		</main>
	);
}
