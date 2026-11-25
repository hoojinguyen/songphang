"use client";
import { useState } from "react";
import { PersonalLedgerList } from "../../components/overview/PersonalLedgerList";
import { Icon } from "../../components/ui/Icon";
import { LoadError } from "../../components/ui/LoadError";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import { useGroups } from "../../lib/groups";
import { usePersonalTransactions } from "../../lib/overview";
import { useMe } from "../../lib/session";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";

export default function PersonalLedgerPage() {
	const me = useMe();
	const groupsQuery = useGroups();
	const [q, setQ] = useState("");
	const [groupId, setGroupId] = useState<string>("");
	const [type, setType] = useState<"expense" | "transfer" | "income" | "">("");

	const transactionsQuery = usePersonalTransactions({
		q: q.trim() || undefined,
		groupId: groupId || undefined,
		type: type || undefined,
	});

	useSessionGuard(me.error ?? transactionsQuery.error ?? groupsQuery.error);

	const allItems =
		transactionsQuery.data?.pages.flatMap((page) => page.items) ?? [];

	return (
		<main className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col gap-4 px-5 pb-24 pt-6">
			<ScreenHeader
				title={vi.ledger.title}
				backHref="/"
				backLabel={vi.common.back}
			/>

			{/* Search input */}
			<div className="relative">
				<input
					type="search"
					value={q}
					onChange={(e) => setQ(e.target.value)}
					placeholder={vi.ledger.searchPlaceholder}
					className="h-12 w-full rounded-[22px] bg-surface pl-10 pr-4 text-sm font-semibold text-ink placeholder:text-placeholder focus:outline-none focus:ring-2 focus:ring-ink"
				/>
				<span className="pointer-events-none absolute left-3.5 top-3.5 text-muted">
					<Icon name="search" size={18} />
				</span>
			</div>

			{/* Filters row */}
			<div className="flex gap-2">
				{/* Group filter dropdown */}
				<select
					value={groupId}
					onChange={(e) => setGroupId(e.target.value)}
					className="h-10 flex-1 truncate rounded-[18px] bg-surface px-3 text-xs font-bold text-ink"
				>
					<option value="">{vi.ledger.allGroups}</option>
					{groupsQuery.data?.map((g) => (
						<option key={g.id} value={g.id}>
							{g.name}
						</option>
					))}
				</select>

				{/* Type filter dropdown */}
				<select
					value={type}
					onChange={(e) =>
						setType(e.target.value as "expense" | "transfer" | "income" | "")
					}
					className="h-10 rounded-[18px] bg-surface px-3 text-xs font-bold text-ink"
				>
					<option value="">{vi.stats.all}</option>
					<option value="expense">{vi.csv.typeExpense}</option>
					<option value="transfer">{vi.csv.typeTransfer}</option>
					<option value="income">{vi.csv.typeIncome}</option>
				</select>
			</div>

			{/* Transactions list */}
			<div className="mt-2 flex-1">
				{transactionsQuery.isPending ? (
					<div aria-busy="true" className="grid gap-2">
						<div className="h-20 rounded-[24px] bg-sunken" />
						<div className="h-20 rounded-[24px] bg-sunken" />
						<div className="h-20 rounded-[24px] bg-sunken" />
					</div>
				) : transactionsQuery.isError ? (
					<LoadError
						onRetry={() => void transactionsQuery.refetch()}
						isRetrying={transactionsQuery.isFetching}
					/>
				) : (
					<PersonalLedgerList
						items={allItems}
						hasNextPage={transactionsQuery.hasNextPage}
						isFetchingNextPage={transactionsQuery.isFetchingNextPage}
						onLoadMore={() => void transactionsQuery.fetchNextPage()}
					/>
				)}
			</div>
		</main>
	);
}
