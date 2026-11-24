"use client";
import type { PersonalTransactionDto } from "@songphang/contract";
import Link from "next/link";
import { formatAmount, formatMoney } from "../../lib/money";
import { dayLabel } from "../../lib/transactions";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";

function formatDelta(delta: number) {
	if (delta > 0) {
		return <span className="font-bold text-credit">+{formatMoney(delta)}</span>;
	}
	if (delta < 0) {
		return (
			<span className="font-bold text-debt">
				−{formatMoney(Math.abs(delta))}
			</span>
		);
	}
	return (
		<span className="font-medium text-muted">{vi.ledger.notParticipating}</span>
	);
}

export function PersonalLedgerList({
	items,
	hasNextPage,
	isFetchingNextPage,
	onLoadMore,
	emptyMessage,
}: {
	items: PersonalTransactionDto[];
	hasNextPage?: boolean;
	isFetchingNextPage?: boolean;
	onLoadMore?: () => void;
	emptyMessage?: string;
}) {
	const now = new Date();

	if (items.length === 0) {
		return (
			<div className="py-8 text-center text-sm font-medium text-muted">
				{emptyMessage ?? vi.overview.emptyTransactions}
			</div>
		);
	}

	return (
		<div className="grid gap-2">
			{items.map((item) => {
				const dateStr = dayLabel(item.occurredAt, now);
				const categoryLabel =
					item.categoryName ??
					(item.category ? vi.expenseForm.categories[item.category] : null);

				return (
					<Link
						key={item.id}
						href={`/g/${item.groupId}/tx/${item.id}`}
						className="flex items-center justify-between gap-3 rounded-[24px] bg-surface p-4 transition-colors hover:bg-surface-raised"
					>
						<div className="min-w-0 flex-1">
							<div className="flex flex-wrap items-center gap-1.5 text-xs text-muted">
								<span className="font-bold text-ink">{item.groupName}</span>
								<span>·</span>
								<span>{dateStr}</span>
								{categoryLabel && (
									<>
										<span>·</span>
										<span className="rounded-md bg-sunken px-1.5 py-0.5 font-medium text-ink">
											{categoryLabel}
										</span>
									</>
								)}
							</div>
							<p className="mt-1 truncate text-sm font-bold text-ink">
								{item.description}
							</p>
							<p className="truncate text-xs text-muted">{item.payerSummary}</p>
						</div>
						<div className="shrink-0 text-right">
							<p className="tabular-nums text-sm font-extrabold text-ink">
								{formatAmount(item.amount)} {vi.common.currency}
							</p>
							<div className="tabular-nums text-xs">
								{formatDelta(item.myDelta)}
							</div>
						</div>
					</Link>
				);
			})}
			{hasNextPage && onLoadMore && (
				<div className="mt-2 flex justify-center">
					<Button
						variant="surface"
						size="md"
						onClick={onLoadMore}
						disabled={isFetchingNextPage}
					>
						{isFetchingNextPage
							? vi.feed.loadingOlder
							: vi.notifications.loadMore}
					</Button>
				</div>
			)}
		</div>
	);
}
