"use client";
import type {
	BalancesResponse,
	CurrentPeriodSummaryDto,
	MemberDebtBreakdownDto,
	MemberDto,
	SettlementCycleDto,
	TransactionListItemDto,
} from "@songphang/contract";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { useGuestLink } from "../../lib/guest-links";
import { useMemberBreakdowns } from "../../lib/member-breakdowns";
import { formatMoney } from "../../lib/money";
import {
	renderShareCardPng,
	type ShareCardMode,
	type ShareCardTheme,
} from "../../lib/share-card-canvas";
import { useThemeMode } from "../../lib/theme";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { useSnackbar } from "../ui/Snackbar";

const PRESET_CAPTIONS = [
	vi.shareCard.preset1,
	vi.shareCard.preset2,
	vi.shareCard.preset3,
] as const;

function resolveInitialTheme(
	mode: "system" | "light" | "dark",
): ShareCardTheme {
	if (mode === "light" || mode === "dark") return mode;
	if (
		typeof window !== "undefined" &&
		window.matchMedia("(prefers-color-scheme: dark)").matches
	) {
		return "dark";
	}
	return "light";
}

export function ShareCardModal({
	open,
	groupId,
	groupName,
	role,
	balances,
	members,
	transactions,
	cycles,
	currentPeriod,
	onClose,
}: {
	open: boolean;
	groupId: string;
	groupName: string;
	role: "owner" | "editor" | "viewer";
	balances: BalancesResponse;
	members: MemberDto[];
	transactions: TransactionListItemDto[];
	cycles: SettlementCycleDto[];
	currentPeriod: CurrentPeriodSummaryDto | undefined;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const showNotice = useSnackbar();
	const [appTheme] = useThemeMode();

	const [mode, setMode] = useState<ShareCardMode>("summary");
	const [theme, setTheme] = useState<ShareCardTheme>(() =>
		resolveInitialTheme(appTheme),
	);
	const [includeExpenses, setIncludeExpenses] = useState(false);
	const [targetKey, setTargetKey] = useState<string>("all");
	const [caption, setCaption] = useState<string>(PRESET_CAPTIONS[0]);
	const [previewUrl, setPreviewUrl] = useState<string | null>(null);
	const [renderedBlob, setRenderedBlob] = useState<Blob | null>(null);
	const [rendering, setRendering] = useState(false);

	const breakdownsQuery = useMemberBreakdowns(groupId, "auto", open);
	const guestLinkQuery = useGuestLink(groupId, open && role !== "viewer");

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			setTheme(resolveInitialTheme(appTheme));
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open, appTheme]);

	const memberName = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;

	const breakdowns: MemberDebtBreakdownDto[] =
		breakdownsQuery.data?.breakdowns ?? [];
	const cycleLabel =
		breakdownsQuery.data?.resolvedFocus.label ?? vi.cycles.currentPeriod;

	const focusedExpenses = useMemo(() => {
		const focus = breakdownsQuery.data?.resolvedFocus;
		const matching = transactions.filter((tx) => {
			if (tx.type !== "expense") return false;
			if (!focus || focus.kind === "all") return true;
			if (focus.kind === "current") return tx.cycleId === null;
			return tx.cycleId === focus.cycleId;
		});
		return matching.map((tx) => ({
			id: tx.id,
			description: tx.description,
			occurredAt: tx.occurredAt,
			amount: tx.amount,
		}));
	}, [breakdownsQuery.data?.resolvedFocus, transactions]);

	const totalSpendAmount = useMemo(() => {
		const focus = breakdownsQuery.data?.resolvedFocus;
		if (focus?.kind === "cycle" && focus.cycleId) {
			const matched = cycles.find((cycle) => cycle.id === focus.cycleId);
			if (matched) return matched.totalExpenseAmount;
		}
		if (focus?.kind === "current" && currentPeriod) {
			return currentPeriod.totalExpenseAmount;
		}
		if (focusedExpenses.length > 0) {
			return focusedExpenses.reduce((sum, item) => sum + item.amount, 0);
		}
		return currentPeriod?.totalExpenseAmount ?? 0;
	}, [
		breakdownsQuery.data?.resolvedFocus,
		cycles,
		currentPeriod,
		focusedExpenses,
	]);

	const guestLinkUrl = guestLinkQuery.data?.active
		? guestLinkQuery.data.url
		: null;

	useEffect(() => {
		if (!open) return;
		let cancelled = false;
		let nextObjectUrl: string | null = null;
		setRendering(true);

		void renderShareCardPng({
			mode,
			theme,
			groupName,
			cycleLabel,
			totalSpendAmount,
			transfers: balances.transfers,
			members,
			breakdowns,
			targetTransferKey: targetKey,
			caption,
			includeExpenses,
			expenses: focusedExpenses,
			guestLinkUrl,
		})
			.then((blob) => {
				if (cancelled) return;
				nextObjectUrl = URL.createObjectURL(blob);
				setRenderedBlob(blob);
				setPreviewUrl((prev) => {
					if (prev) URL.revokeObjectURL(prev);
					return nextObjectUrl;
				});
			})
			.catch(() => {
				if (!cancelled) showNotice({ text: vi.common.saveError });
			})
			.finally(() => {
				if (!cancelled) setRendering(false);
			});

		return () => {
			cancelled = true;
			if (nextObjectUrl) URL.revokeObjectURL(nextObjectUrl);
		};
	}, [
		open,
		mode,
		theme,
		groupName,
		cycleLabel,
		totalSpendAmount,
		balances.transfers,
		members,
		breakdowns,
		targetKey,
		caption,
		includeExpenses,
		focusedExpenses,
		guestLinkUrl,
		showNotice,
	]);

	const canNativeShare = useMemo(() => {
		if (
			!renderedBlob ||
			typeof navigator === "undefined" ||
			typeof navigator.canShare !== "function"
		) {
			return false;
		}
		const file = new File([renderedBlob], `songphang-${mode}.png`, {
			type: "image/png",
		});
		try {
			return navigator.canShare({ files: [file] });
		} catch {
			return false;
		}
	}, [renderedBlob, mode]);

	const handleNativeShare = async () => {
		if (!renderedBlob) return;
		const file = new File([renderedBlob], `songphang-${mode}.png`, {
			type: "image/png",
		});
		try {
			await navigator.share({ files: [file], title: groupName });
		} catch (error) {
			if (!(error instanceof DOMException && error.name === "AbortError")) {
				showNotice({ text: vi.common.saveError });
			}
		}
	};

	const handleDownload = () => {
		if (!renderedBlob) return;
		const url = URL.createObjectURL(renderedBlob);
		const anchor = document.createElement("a");
		anchor.href = url;
		anchor.download = `songphang-${mode}.png`;
		anchor.click();
		setTimeout(() => URL.revokeObjectURL(url), 1000);
	};

	const handleCopyImage = async () => {
		if (!renderedBlob) return;
		try {
			await navigator.clipboard.write([
				new ClipboardItem({ "image/png": renderedBlob }),
			]);
			showNotice({ text: vi.shareCard.copiedImage });
		} catch {
			showNotice({ text: vi.common.saveError });
		}
	};

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto max-h-[92dvh] w-[calc(100%-24px)] max-w-[440px] overflow-hidden rounded-[30px] bg-bg p-0 text-ink backdrop:bg-ink/45"
		>
			<div className="flex max-h-[92dvh] flex-col">
				<div className="flex items-center justify-between gap-2 border-b border-sunken px-5 py-4">
					<h2 id={titleId} className="text-base font-black">
						{vi.shareCard.openAction}
					</h2>
					<button
						type="button"
						aria-label={vi.common.cancel}
						onClick={onClose}
						className="flex h-11 w-11 items-center justify-center rounded-full bg-surface text-ink"
					>
						<Icon name="close" size={18} />
					</button>
				</div>

				<div className="flex-1 space-y-4 overflow-y-auto p-5">
					<div className="flex gap-1.5 rounded-[18px] bg-sunken p-1">
						<button
							type="button"
							aria-pressed={mode === "summary"}
							onClick={() => setMode("summary")}
							className={`min-h-11 flex-1 rounded-[14px] px-3 text-xs font-extrabold ${
								mode === "summary"
									? "bg-surface text-ink shadow-sm"
									: "text-muted"
							}`}
						>
							{vi.shareCard.modeSummary}
						</button>
						<button
							type="button"
							aria-pressed={mode === "reminder"}
							onClick={() => setMode("reminder")}
							className={`min-h-11 flex-1 rounded-[14px] px-3 text-xs font-extrabold ${
								mode === "reminder"
									? "bg-surface text-ink shadow-sm"
									: "text-muted"
							}`}
						>
							{vi.shareCard.modeReminder}
						</button>
					</div>

					<div className="flex gap-2">
						{(["light", "dark"] as const).map((option) => (
							<button
								key={option}
								type="button"
								aria-pressed={theme === option}
								onClick={() => setTheme(option)}
								className={`min-h-11 flex-1 rounded-pill px-3 text-xs font-bold ${
									theme === option
										? "bg-ink text-on-ink"
										: "bg-surface text-ink"
								}`}
							>
								{option === "light"
									? vi.shareCard.themeLight
									: vi.shareCard.themeDark}
							</button>
						))}
					</div>

					{mode === "summary" ? (
						<label className="flex min-h-11 items-center justify-between gap-3 rounded-[20px] bg-surface px-4 py-2 text-xs font-bold text-ink">
							<span>{vi.shareCard.includeExpenses}</span>
							<input
								type="checkbox"
								checked={includeExpenses}
								onChange={(event) => setIncludeExpenses(event.target.checked)}
								className="size-5 accent-ink"
							/>
						</label>
					) : (
						<div className="grid gap-3">
							<label className="grid gap-1.5 text-xs font-bold text-muted">
								{vi.shareCard.targetLabel}
								<select
									value={targetKey}
									onChange={(event) => setTargetKey(event.target.value)}
									className="h-11 min-w-0 rounded-[18px] bg-surface px-3 text-xs font-bold text-ink"
								>
									<option value="all">{vi.shareCard.targetAll}</option>
									{balances.transfers.map((transfer) => {
										const key = `${transfer.fromMemberId}-${transfer.toMemberId}`;
										return (
											<option key={key} value={key}>
												{memberName(transfer.fromMemberId)} →{" "}
												{memberName(transfer.toMemberId)} (
												{formatMoney(transfer.amount)})
											</option>
										);
									})}
								</select>
							</label>

							<div className="grid gap-2">
								<span className="text-xs font-bold text-muted">
									{vi.shareCard.captionLabel}
								</span>
								<div className="grid gap-1.5">
									{PRESET_CAPTIONS.map((preset) => (
										<button
											key={preset}
											type="button"
											aria-pressed={caption === preset}
											onClick={() => setCaption(preset)}
											className={`min-h-11 rounded-[16px] px-3 py-2 text-left text-xs font-semibold ${
												caption === preset
													? "bg-ink text-on-ink"
													: "bg-surface text-ink"
											}`}
										>
											{preset}
										</button>
									))}
								</div>
								<input
									type="text"
									maxLength={100}
									value={caption}
									onChange={(event) => setCaption(event.target.value)}
									className="h-11 min-w-0 rounded-[16px] bg-surface px-3 text-xs font-semibold text-ink"
								/>
							</div>
						</div>
					)}

					<div className="overflow-hidden rounded-[24px] bg-sunken p-2">
						{previewUrl ? (
							<img
								src={previewUrl}
								alt={vi.shareCard.openAction}
								className="w-full rounded-[18px]"
							/>
						) : (
							<div
								aria-busy="true"
								className="h-72 rounded-[18px] bg-surface"
							/>
						)}
					</div>
				</div>

				<div className="grid gap-2 border-t border-sunken p-4">
					{canNativeShare && (
						<Button
							variant="accent"
							allowOffline
							disabled={!renderedBlob || rendering}
							onClick={() => {
								void handleNativeShare();
							}}
						>
							{vi.shareCard.shareImage}
						</Button>
					)}
					<div className="flex gap-2">
						<Button
							variant={canNativeShare ? "surface" : "accent"}
							allowOffline
							className="flex-1 text-xs"
							disabled={!renderedBlob || rendering}
							onClick={handleDownload}
						>
							{vi.shareCard.downloadPng}
						</Button>
						<Button
							variant="surface"
							allowOffline
							className="flex-1 text-xs"
							disabled={!renderedBlob || rendering}
							onClick={() => {
								void handleCopyImage();
							}}
						>
							{vi.shareCard.copyImage}
						</Button>
					</div>
				</div>
			</div>
		</dialog>
	);
}
