"use client";
import type { MemberDto } from "@songphang/contract";
import Link from "next/link";
import { Fragment, useEffect, useLayoutEffect, useRef, useState } from "react";
import { dayLabel, type useTransactions } from "../../lib/transactions";
import { t, vi } from "../../messages/vi";
import { LoadError } from "../ui/LoadError";
import { ExpenseRow } from "./ExpenseRow";
import { LedgerPill } from "./LedgerPill";
import { NewItemsPill } from "./NewItemsPill";
export function ExpenseStream({
	groupId,
	canEdit = false,
	query,
	members,
	myMemberId,
}: {
	groupId: string;
	canEdit?: boolean;
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
	const newest = transactions.at(-1)?.id;
	const previousNewest = useRef<string | undefined>(undefined);
	const [newItems, setNewItems] = useState(false);
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
		} else if (newest !== previousNewest.current) {
			const away =
				scroll.current.scrollHeight -
					scroll.current.scrollTop -
					scroll.current.clientHeight >
				scroll.current.clientHeight;
			if (away) setNewItems(true);
			else scroll.current.scrollTop = scroll.current.scrollHeight;
		}
		previousNewest.current = newest;
	}, [count, newest]);
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
		<>
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
								<FeedLink
									newest={transaction.id === newest}
									href={`/g/${groupId}/tx/${transaction.id}`}
									enabled={canEdit}
									label={t(vi.feed.editRow, {
										description: transaction.description,
									})}
								>
									{transaction.type === "expense" ? (
										<ExpenseRow
											transaction={transaction}
											members={members}
											myMemberId={myMemberId}
										/>
									) : (
										<LedgerPill
											transaction={transaction}
											members={members}
											myMemberId={myMemberId}
										/>
									)}
								</FeedLink>
							</Fragment>
						);
					})}
				</div>
			</div>
			{newItems && (
				<NewItemsPill
					onClick={() => {
						if (scroll.current)
							scroll.current.scrollTop = scroll.current.scrollHeight;
						setNewItems(false);
					}}
				/>
			)}
		</>
	);
}

function FeedLink({
	href,
	enabled,
	newest,
	label,
	children,
}: {
	href: string;
	enabled: boolean;
	newest: boolean;
	label: string;
	children: import("react").ReactNode;
}) {
	const content = <div className={newest ? "row-enter" : ""}>{children}</div>;
	return enabled ? (
		<Link href={href} aria-label={label}>
			{content}
		</Link>
	) : (
		content
	);
}
