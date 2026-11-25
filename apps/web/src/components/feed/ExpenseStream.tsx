"use client";
import type { CategoryDto, MemberDto } from "@songphang/contract";
import Link from "next/link";
import { Fragment, useEffect, useLayoutEffect, useRef, useState } from "react";
import { dayLabel, type useTransactions } from "../../lib/transactions";
import { t, vi } from "../../messages/vi";
import { useDesktopInspector } from "../layout/DesktopInspectorContext";
import { LoadError } from "../ui/LoadError";
import { ExpenseRow } from "./ExpenseRow";
import { LedgerPill } from "./LedgerPill";
import { NewItemsPill } from "./NewItemsPill";
export function ExpenseStream({
	groupId,
	query,
	members,
	categories = [],
	myMemberId,
	onAtTopChange,
}: {
	groupId: string;
	query: ReturnType<typeof useTransactions>;
	members: MemberDto[];
	categories?: CategoryDto[];
	myMemberId: string | null;
	onAtTopChange?: (atTop: boolean) => void;
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
		if (!scroll.current) return;
		if (count === 0) {
			onAtTopChange?.(true);
			return;
		}
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
		onAtTopChange?.(scroll.current.scrollTop <= 24);
	}, [count, newest, onAtTopChange]);
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
				onScroll={(event) =>
					onAtTopChange?.(event.currentTarget.scrollTop <= 24)
				}
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
									groupId={groupId}
									transactionId={transaction.id}
									href={`/g/${groupId}/tx/${transaction.id}/view`}
									enabled={true}
									label={t(vi.feed.viewRow, {
										description: transaction.description,
									})}
								>
									{transaction.type === "expense" ? (
										<ExpenseRow
											transaction={transaction}
											members={members}
											categories={categories}
											myMemberId={myMemberId}
										/>
									) : (
										<LedgerPill
											groupId={groupId}
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
	groupId,
	transactionId,
	enabled,
	newest,
	label,
	children,
}: {
	href: string;
	groupId: string;
	transactionId: string;
	enabled: boolean;
	newest: boolean;
	label: string;
	children: import("react").ReactNode;
}) {
	const { selectedTx, selectTx } = useDesktopInspector();
	const isSelected =
		selectedTx?.groupId === groupId &&
		selectedTx.transactionId === transactionId;
	const content = (
		<div
			className={`${newest ? "row-enter" : ""} ${isSelected ? "rounded-[24px] ring-2 ring-ink" : ""}`}
		>
			{children}
		</div>
	);
	return enabled ? (
		<Link
			href={href}
			aria-label={label}
			onClick={(event) => {
				if (
					event.metaKey ||
					event.ctrlKey ||
					event.shiftKey ||
					event.altKey ||
					event.button !== 0
				) {
					return;
				}
				if (window.matchMedia("(min-width: 1280px)").matches) {
					event.preventDefault();
					selectTx(groupId, transactionId);
				}
			}}
		>
			{content}
		</Link>
	) : (
		content
	);
}
