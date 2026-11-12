"use client";
import type { MemberDto } from "@songphang/contract";
import { Fragment, useEffect, useLayoutEffect, useRef } from "react";
import { dayLabel, type useTransactions } from "../../lib/transactions";
import { vi } from "../../messages/vi";
import { LoadError } from "../ui/LoadError";
import { ExpenseRow } from "./ExpenseRow";
export function ExpenseStream({
	query,
	members,
	myMemberId,
}: {
	query: ReturnType<typeof useTransactions>;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const scroll = useRef<HTMLDivElement>(null);
	const sentinel = useRef<HTMLDivElement>(null);
	const anchor = useRef<{ height: number; top: number } | null>(null);
	const initialized = useRef(false);
	const transactions =
		query.data?.pages.flatMap((page) => page.transactions).toReversed() ?? [];
	const count = transactions.length;
	useLayoutEffect(() => {
		if (!scroll.current || count === 0) return;
		if (anchor.current) {
			scroll.current.scrollTop =
				anchor.current.top +
				scroll.current.scrollHeight -
				anchor.current.height;
			anchor.current = null;
		} else if (!initialized.current) {
			scroll.current.scrollTop = scroll.current.scrollHeight;
			initialized.current = true;
		}
	}, [count]);
	useEffect(() => {
		const container = scroll.current;
		const target = sentinel.current;
		if (!container || !target) return;
		const observer = new IntersectionObserver(
			(entries) => {
				if (
					entries.some((entry) => entry.isIntersecting) &&
					query.hasNextPage &&
					!query.isFetchingNextPage &&
					container.scrollTop < 100
				) {
					anchor.current = {
						height: container.scrollHeight,
						top: container.scrollTop,
					};
					void query.fetchNextPage();
				}
			},
			{ root: container },
		);
		observer.observe(target);
		return () => observer.disconnect();
	}, [query.hasNextPage, query.isFetchingNextPage, query.fetchNextPage]);
	return (
		<div
			ref={scroll}
			className="min-h-0 flex-1 overflow-y-auto [overflow-anchor:none]"
		>
			<div ref={sentinel} className="h-px" />
			{query.isFetchingNextPage && (
				<p className="py-3 text-center text-xs text-muted">
					{vi.feed.loadingOlder}
				</p>
			)}
			{query.isFetchNextPageError && (
				<LoadError
					onRetry={() => {
						void query.fetchNextPage();
					}}
					isRetrying={query.isFetchingNextPage}
				/>
			)}
			<div className="flex flex-col gap-3 py-3">
				{transactions.map((transaction, index) => {
					const label = dayLabel(transaction.occurredAt, new Date());
					const previous = transactions[index - 1];
					const showsDay =
						!previous || dayLabel(previous.occurredAt, new Date()) !== label;
					return (
						<Fragment key={transaction.id}>
							{showsDay && (
								<p className="py-2 text-center text-xs font-semibold text-muted">
									{label}
								</p>
							)}
							<ExpenseRow
								transaction={transaction}
								members={members}
								myMemberId={myMemberId}
							/>
						</Fragment>
					);
				})}
			</div>
		</div>
	);
}
