"use client";
import type { GuestTransactionDto } from "@songphang/contract";
import { useState } from "react";
import { useGuestGroupView } from "../../lib/guest-links";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { useThemeMode } from "../../lib/theme";
import { t, vi } from "../../messages/vi";
import { CopyRow } from "../pay/CopyRow";
import { QrCard } from "../pay/QrCard";
import { paymentChannelLabel } from "../pay/TransferProofFields";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { LoadError } from "../ui/LoadError";
import { MemberShape } from "../ui/MemberShape";
import { GuestExpenseDetailModal } from "./GuestExpenseDetailModal";

export function GuestGroupPage({ token }: { token: string }) {
	const [selectedCycleId, setSelectedCycleId] = useState<
		"current" | string | undefined
	>(undefined);
	const [expandedTransferKey, setExpandedTransferKey] = useState<string | null>(
		null,
	);
	const [selectedTx, setSelectedTx] = useState<GuestTransactionDto | null>(
		null,
	);
	const [themeMode, setThemeMode] = useThemeMode();

	const guestQuery = useGuestGroupView(token, {
		...(selectedCycleId ? { cycleId: selectedCycleId } : {}),
	});

	if (guestQuery.error?.status === 404) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[460px] content-center px-5 text-center">
				<section className="grid gap-3 rounded-[30px] bg-surface p-6">
					<h1 className="text-lg font-black">{vi.common.appName}</h1>
					<p className="text-sm font-semibold text-muted">
						{vi.guestLink.invalidOrRevoked}
					</p>
				</section>
			</main>
		);
	}

	if (guestQuery.isPending) {
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[680px] gap-4 px-5 py-6"
			>
				<div className="h-24 rounded-card bg-sunken" />
				<div className="h-44 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	}

	if (guestQuery.isError || !guestQuery.data) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[460px] content-center px-5">
				<LoadError
					onRetry={() => {
						void guestQuery.refetch();
					}}
					isRetrying={guestQuery.isFetching}
				/>
			</main>
		);
	}

	const pages = guestQuery.data.pages;
	const data = pages[0];
	if (!data) return null;

	const transactions = pages.flatMap((page) => page.transactions.items);
	const peopleCount = data.members.filter((m) => m.kind === "person").length;
	const activeCycle =
		data.selectedCycleId === "current"
			? null
			: (data.cycles.find((c) => c.id === data.selectedCycleId) ?? null);
	const periodTotal = activeCycle
		? activeCycle.totalExpenseAmount
		: data.currentPeriod.totalExpenseAmount;

	const memberName = (id: string) =>
		data.members.find((m) => m.id === id)?.name ?? vi.activity.someone;

	const toggleTheme = () => {
		setThemeMode(themeMode === "dark" ? "light" : "dark");
	};

	return (
		<main className="mx-auto flex min-h-dvh max-w-[680px] flex-col gap-5 px-5 py-6 pb-16">
			<header className="grid gap-3 rounded-[30px] bg-surface p-5">
				<div className="flex items-center justify-between gap-2">
					<span className="inline-flex min-h-8 items-center rounded-pill bg-sunken px-3 text-[11px] font-extrabold text-ink">
						{vi.common.appName} · {vi.guestLink.readonlyBadge}
					</span>
					<button
						type="button"
						onClick={toggleTheme}
						aria-label={
							themeMode === "dark"
								? vi.shareCard.themeLight
								: vi.shareCard.themeDark
						}
						className="inline-flex min-h-11 items-center gap-1.5 rounded-pill bg-sunken px-3 text-xs font-bold text-ink"
					>
						<Icon name={themeMode === "dark" ? "sun" : "moon"} size={16} />
						<span>
							{themeMode === "dark"
								? vi.shareCard.themeLight
								: vi.shareCard.themeDark}
						</span>
					</button>
				</div>

				<div>
					<h1 className="text-[26px] font-black leading-tight text-ink">
						{data.group.name}
					</h1>
					<p className="mt-1 text-xs font-semibold text-muted">
						{t(vi.members.memberCount, { count: String(peopleCount) })} ·{" "}
						{formatMoney(periodTotal)}
					</p>
				</div>

				{data.cycles.length > 0 && (
					<div className="flex flex-wrap gap-1.5">
						<button
							type="button"
							aria-pressed={data.selectedCycleId === "current"}
							onClick={() => setSelectedCycleId("current")}
							className={`min-h-11 rounded-pill px-3.5 text-xs font-bold ${
								data.selectedCycleId === "current"
									? "bg-ink text-on-ink"
									: "bg-sunken text-ink"
							}`}
						>
							{vi.cycles.currentPeriod}
						</button>
						{data.cycles.map((cycle) => (
							<button
								key={cycle.id}
								type="button"
								aria-pressed={data.selectedCycleId === cycle.id}
								onClick={() => setSelectedCycleId(cycle.id)}
								className={`min-h-11 rounded-pill px-3.5 text-xs font-bold ${
									data.selectedCycleId === cycle.id
										? "bg-ink text-on-ink"
										: "bg-sunken text-ink"
								}`}
							>
								{cycle.title}
							</button>
						))}
					</div>
				)}
			</header>

			<section className="grid gap-3">
				<h2 className="text-lg font-black text-ink">
					{data.transfers.length > 0
						? t(vi.balances.headline, { count: String(data.transfers.length) })
						: vi.balances.allSettledTitle}
				</h2>

				{data.transfers.length === 0 ? (
					<div className="rounded-[26px] bg-accent p-5 text-on-accent">
						<p className="font-bold">{vi.balances.allSettledHint}</p>
					</div>
				) : (
					<div className="grid gap-3">
						{data.transfers.map((transfer) => {
							const key = `${transfer.fromMemberId}-${transfer.toMemberId}`;
							const expanded = expandedTransferKey === key;
							const fromMember = data.members.find(
								(m) => m.id === transfer.fromMemberId,
							);
							const toMember = data.members.find(
								(m) => m.id === transfer.toMemberId,
							);
							const breakdown = data.breakdowns.find(
								(b) => b.memberId === transfer.fromMemberId,
							);
							const debtorTransfers = data.transfers.filter(
								(t) => t.fromMemberId === transfer.fromMemberId,
							);
							const bank = transfer.payTo.find((m) => m.kind === "bank");
							const wallets = transfer.payTo.filter((m) => m.kind !== "bank");

							return (
								<article
									key={key}
									className="grid gap-3 rounded-[26px] bg-surface p-4"
								>
									<button
										type="button"
										aria-expanded={expanded}
										onClick={() =>
											setExpandedTransferKey(expanded ? null : key)
										}
										className="flex min-h-11 w-full items-center justify-between gap-3 text-left"
									>
										<div className="flex min-w-0 flex-1 items-center gap-2.5">
											{fromMember && <MemberShape {...fromMember} size={34} />}
											<div className="min-w-0 flex-1">
												<p className="truncate text-sm font-extrabold text-ink">
													{fromMember?.name ?? vi.activity.someone} →{" "}
													{toMember?.name ?? vi.activity.someone}
												</p>
												<p className="text-xs font-bold text-muted underline">
													{vi.breakdown.viewAction}
												</p>
											</div>
										</div>
										<span className="shrink-0 whitespace-nowrap tabular-nums text-base font-black text-ink">
											{formatMoney(transfer.amount)}
										</span>
									</button>

									{expanded && (
										<div className="grid gap-4 border-t border-sunken pt-4">
											{breakdown && (
												<div className="grid gap-2.5 rounded-[20px] bg-sunken p-4 text-xs">
													<p className="font-black text-ink">
														{vi.breakdown.title} · {breakdown.memberName} (
														{data.resolvedFocus.label})
													</p>
													{(data.cycles.length > 0 ||
														breakdown.carryOverBalance !== 0) && (
														<div className="flex justify-between gap-2">
															<span className="text-muted">
																{vi.breakdown.carryOver}
															</span>
															<span className="tabular-nums font-bold">
																{formatSignedAmount(breakdown.carryOverBalance)}{" "}
																{vi.common.currency}
															</span>
														</div>
													)}
													{breakdown.lines.map((line) => {
														const date = new Date(line.occurredAt);
														const dateText = `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}`;
														return (
															<div
																key={line.transactionId}
																className="flex items-start justify-between gap-2 rounded-[14px] bg-surface px-3 py-2"
															>
																<div className="min-w-0 flex-1">
																	<p className="font-bold text-ink">
																		{line.description}
																	</p>
																	<p className="text-[11px] text-muted">
																		{dateText} · {line.payerSummary} ·{" "}
																		{formatMoney(line.totalAmount)}
																	</p>
																</div>
																<span
																	className={`shrink-0 tabular-nums font-extrabold ${
																		line.delta > 0
																			? "text-credit"
																			: line.delta < 0
																				? "text-debt"
																				: "text-muted"
																	}`}
																>
																	{formatSignedAmount(line.delta)}{" "}
																	{vi.common.currency}
																</span>
															</div>
														);
													})}
													{breakdown.postCycleDelta !== 0 && (
														<div className="flex justify-between gap-2">
															<span className="text-muted">
																{vi.breakdown.postCycleDelta}
															</span>
															<span className="tabular-nums font-bold">
																{formatSignedAmount(breakdown.postCycleDelta)}{" "}
																{vi.common.currency}
															</span>
														</div>
													)}
													<div className="flex justify-between gap-2 border-t border-border-subtle pt-2 font-black text-ink">
														<span>{vi.breakdown.currentBalance}</span>
														<span className="tabular-nums">
															{formatSignedAmount(breakdown.netBalance)}{" "}
															{vi.common.currency}
														</span>
													</div>
													{(debtorTransfers.length > 1 ||
														Math.abs(breakdown.netBalance) !==
															transfer.amount) && (
														<div className="grid gap-1 border-t border-border-subtle pt-2">
															<span className="font-extrabold text-ink">
																{vi.breakdown.transferAllocation}
															</span>
															{debtorTransfers.map((item) => (
																<div
																	key={`${item.fromMemberId}-${item.toMemberId}`}
																	className="flex justify-between gap-2 text-muted"
																>
																	<span>
																		{memberName(item.fromMemberId)} →{" "}
																		{memberName(item.toMemberId)}
																	</span>
																	<span className="tabular-nums font-bold text-ink">
																		{formatMoney(item.amount)}
																	</span>
																</div>
															))}
														</div>
													)}
												</div>
											)}

											{bank && (
												<div className="grid gap-3">
													{bank.qrPayload && (
														<QrCard
															payload={bank.qrPayload}
															label={t(vi.pay.title, {
																to: toMember?.name ?? "",
															})}
															hint={vi.pay.qrHint}
														/>
													)}
													<div className="grid gap-1.5 rounded-[20px] bg-sunken p-4">
														<CopyRow
															label={vi.payment.bank}
															value={bank.bankShortName}
														/>
														<CopyRow
															label={vi.payment.accountNumber}
															value={bank.accountNumber}
														/>
														<CopyRow
															label={vi.payment.accountName}
															value={bank.accountName}
														/>
														<CopyRow
															label={vi.pay.purpose}
															value={transfer.purpose}
														/>
													</div>
												</div>
											)}

											{wallets.length > 0 && (
												<div className="grid gap-1.5 rounded-[20px] bg-sunken p-4">
													{wallets.map((wallet) => (
														<CopyRow
															key={wallet.kind}
															label=""
															value={t(
																wallet.kind === "momo"
																	? vi.pay.momoRow
																	: vi.pay.zalopayRow,
																{ phone: wallet.phone },
															)}
															copyValue={wallet.phone}
														/>
													))}
												</div>
											)}
										</div>
									)}
								</article>
							);
						})}
					</div>
				)}
			</section>

			<section className="grid gap-3">
				<h2 className="text-lg font-black text-ink">
					{vi.groupSegments.expenses}
				</h2>

				{transactions.length === 0 ? (
					<div className="rounded-[24px] bg-surface p-6 text-center text-sm font-semibold text-muted">
						{vi.filter.noResult}
					</div>
				) : (
					<div className="grid gap-2.5">
						{transactions.map((tx) => {
							const payer = data.members.find(
								(m) => m.id === tx.payers[0]?.memberId,
							);
							const date = new Date(tx.occurredAt);
							const dateStr = `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}`;
							const subtitle =
								tx.type === "transfer" && tx.paymentChannel
									? `${paymentChannelLabel(tx.paymentChannel)}${tx.paymentNote ? ` · “${tx.paymentNote}”` : ""}`
									: tx.payers.map((p) => memberName(p.memberId)).join(" · ");

							return (
								<button
									key={tx.id}
									type="button"
									onClick={() => setSelectedTx(tx)}
									className="flex min-h-11 w-full items-center justify-between gap-3 rounded-[22px] bg-surface p-4 text-left transition-colors hover:bg-surface-elevated"
								>
									<div className="flex min-w-0 flex-1 items-center gap-3">
										{payer && <MemberShape {...payer} size={32} />}
										<div className="min-w-0 flex-1">
											<p className="truncate text-sm font-extrabold text-ink">
												{tx.description}
											</p>
											<p className="mt-0.5 truncate text-xs font-semibold text-muted">
												{dateStr} · {subtitle}
											</p>
										</div>
									</div>
									<span className="shrink-0 whitespace-nowrap tabular-nums text-sm font-black text-ink">
										{formatMoney(tx.amount)}
									</span>
								</button>
							);
						})}
					</div>
				)}

				{guestQuery.hasNextPage && (
					<Button
						variant="surface"
						allowOffline
						disabled={guestQuery.isFetchingNextPage}
						onClick={() => {
							void guestQuery.fetchNextPage();
						}}
					>
						{vi.notifications.loadMore}
					</Button>
				)}
			</section>

			<GuestExpenseDetailModal
				token={token}
				transaction={selectedTx}
				members={data.members}
				onClose={() => setSelectedTx(null)}
			/>
		</main>
	);
}
