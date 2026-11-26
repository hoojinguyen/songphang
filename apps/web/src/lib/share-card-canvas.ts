"use client";
import type {
	AnyMemberColorCode,
	AnyMemberShapeCode,
	BalancesResponse,
	MemberDebtBreakdownDto,
	MemberDto,
} from "@songphang/contract";
import { create } from "qrcode";
import { vi } from "../messages/vi";
import { formatMoney, formatSignedAmount } from "./money";

export type ShareCardMode = "summary" | "reminder";
export type ShareCardTheme = "light" | "dark";

export type ShareCardExpenseDigestItem = {
	id: string;
	description: string;
	occurredAt: string;
	amount: number;
};

export type ShareCardRenderOptions = {
	mode: ShareCardMode;
	theme: ShareCardTheme;
	groupName: string;
	cycleLabel: string;
	totalSpendAmount: number;
	transfers: BalancesResponse["transfers"];
	members: MemberDto[];
	breakdowns: MemberDebtBreakdownDto[];
	targetTransferKey: string | "all";
	caption: string;
	includeExpenses: boolean;
	expenses: ShareCardExpenseDigestItem[];
	guestLinkUrl: string | null;
};

type Palette = {
	bg: string;
	surface: string;
	sunken: string;
	border: string;
	ink: string;
	muted: string;
	accent: string;
	onAccent: string;
	credit: string;
	debt: string;
	shapes: Record<AnyMemberColorCode, string>;
};

const PALETTES: Record<ShareCardTheme, Palette> = {
	light: {
		bg: "#F6F2FB",
		surface: "#FFFFFF",
		sunken: "#E9E4F3",
		border: "#E3DDF0",
		ink: "#1C1B22",
		muted: "#5A5766",
		accent: "#FFD84D",
		onAccent: "#1C1B22",
		credit: "#0E7A4B",
		debt: "#C73826",
		shapes: {
			mint: "#9EEBC0",
			sky: "#9CCBFF",
			coral: "#FF8A73",
			lilac: "#D3B8FF",
			sun: "#FFD84D",
		},
	},
	dark: {
		bg: "#111016",
		surface: "#1B1924",
		sunken: "#262333",
		border: "#343045",
		ink: "#F5F3FA",
		muted: "#A8A3BA",
		accent: "#F5C93B",
		onAccent: "#1C1B22",
		credit: "#5FE0A2",
		debt: "#FF8A7A",
		shapes: {
			mint: "#6BD9A2",
			sky: "#70B4FF",
			coral: "#FF7F66",
			lilac: "#BC9AFF",
			sun: "#F5C93B",
		},
	},
};

const LOGICAL_WIDTH = 390;
const SCALE = 3;
const PAD = 18;
const CARD_PAD = 16;
const CONTENT_WIDTH = LOGICAL_WIDTH - PAD * 2;
const INNER_WIDTH = CONTENT_WIDTH - CARD_PAD * 2;
const FONT_FAMILY = '"Be Vietnam Pro", "Be Vietnam Pro Fallback", sans-serif';

function fontSpec(weight: number, size: number): string {
	return `${weight} ${size}px ${FONT_FAMILY}`;
}

function wrapText(
	ctx: CanvasRenderingContext2D,
	text: string,
	maxWidth: number,
): string[] {
	const words = text.split(/\s+/).filter(Boolean);
	if (words.length === 0) return [""];
	const lines: string[] = [];
	let current = "";
	for (const word of words) {
		const candidate = current ? `${current} ${word}` : word;
		if (ctx.measureText(candidate).width <= maxWidth) {
			current = candidate;
		} else if (ctx.measureText(word).width > maxWidth) {
			if (current) lines.push(current);
			let chunk = "";
			for (const ch of Array.from(word)) {
				const nextChunk = chunk + ch;
				if (ctx.measureText(nextChunk).width > maxWidth && chunk) {
					lines.push(chunk);
					chunk = ch;
				} else {
					chunk = nextChunk;
				}
			}
			current = chunk;
		} else {
			if (current) lines.push(current);
			current = word;
		}
	}
	if (current) lines.push(current);
	return lines;
}

function roundRectPath(
	ctx: CanvasRenderingContext2D,
	x: number,
	y: number,
	w: number,
	h: number,
	radii: number | [number, number, number, number],
) {
	ctx.beginPath();
	ctx.roundRect(x, y, w, h, radii);
}

function drawMemberShape(
	ctx: CanvasRenderingContext2D,
	x: number,
	y: number,
	size: number,
	shape: AnyMemberShapeCode,
	color: AnyMemberColorCode,
	palette: Palette,
) {
	ctx.save();
	ctx.fillStyle = palette.shapes[color];
	const cx = x + size / 2;
	const cy = y + size / 2;

	if (shape === "circle" || shape === "fund") {
		ctx.beginPath();
		ctx.arc(cx, cy, size / 2, 0, Math.PI * 2);
		ctx.fill();
	} else if (shape === "diamond") {
		const side = size * 0.72;
		ctx.translate(cx, cy);
		ctx.rotate(Math.PI / 4);
		roundRectPath(ctx, -side / 2, -side / 2, side, side, side * 0.24);
		ctx.fill();
	} else if (shape === "squircle") {
		roundRectPath(ctx, x, y, size, size, size * 0.38);
		ctx.fill();
	} else {
		const side = size * 0.86;
		const offset = (size - side) / 2;
		roundRectPath(ctx, x + offset, y + offset, side, side, [
			side * 0.5,
			side * 0.1,
			side * 0.5,
			side * 0.1,
		]);
		ctx.fill();
	}
	ctx.restore();
}

function drawQrBox(
	ctx: CanvasRenderingContext2D,
	x: number,
	y: number,
	boxSize: number,
	payload: string,
) {
	const matrix = create(payload, { errorCorrectionLevel: "M" }).modules;
	const quiet = 2;
	const totalModules = matrix.size + quiet * 2;
	const cellSize = Math.floor(boxSize / totalModules);
	const qrDrawSize = cellSize * totalModules;
	const startX = x + Math.floor((boxSize - qrDrawSize) / 2);
	const startY = y + Math.floor((boxSize - qrDrawSize) / 2);

	ctx.save();
	ctx.fillStyle = "#FFFFFF";
	roundRectPath(ctx, x, y, boxSize, boxSize, 16);
	ctx.fill();

	ctx.fillStyle = "#1C1B22";
	for (let row = 0; row < matrix.size; row++) {
		for (let col = 0; col < matrix.size; col++) {
			const value = matrix.data[row * matrix.size + col];
			if (value) {
				ctx.fillRect(
					startX + (col + quiet) * cellSize,
					startY + (row + quiet) * cellSize,
					cellSize,
					cellSize,
				);
			}
		}
	}
	ctx.restore();
}

function formatShortDate(iso: string): string {
	const date = new Date(iso);
	return `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}`;
}

type ReceiverSummary = {
	memberName: string;
	bank: Extract<
		BalancesResponse["transfers"][number]["payTo"][number],
		{ kind: "bank" }
	> | null;
	wallets: Array<
		Exclude<
			BalancesResponse["transfers"][number]["payTo"][number],
			{ kind: "bank" }
		>
	>;
};

function collectReceivers(
	transfers: BalancesResponse["transfers"],
	members: MemberDto[],
): ReceiverSummary[] {
	const map = new Map<string, ReceiverSummary>();
	for (const transfer of transfers) {
		if (map.has(transfer.toMemberId)) continue;
		const member = members.find((m) => m.id === transfer.toMemberId);
		const bank = transfer.payTo.find((m) => m.kind === "bank") ?? null;
		const wallets = transfer.payTo.filter((m) => m.kind !== "bank");
		if (bank || wallets.length > 0) {
			map.set(transfer.toMemberId, {
				memberName: member?.name ?? vi.activity.someone,
				bank,
				wallets,
			});
		}
	}
	return [...map.values()];
}

function clipText(
	ctx: CanvasRenderingContext2D,
	text: string,
	maxWidth: number,
): string {
	let clipped = text;
	while (ctx.measureText(clipped).width > maxWidth && clipped.length > 3) {
		clipped = `${clipped.slice(0, -2)}…`;
	}
	return clipped;
}

type SectionParams = {
	ctx: CanvasRenderingContext2D;
	options: ShareCardRenderOptions;
	palette: Palette;
	y: number;
	draw: boolean;
};

function drawHeaderSection({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	ctx.font = fontSpec(800, 11);
	const brandText = vi.common.appName.toLocaleUpperCase("vi");
	ctx.font = fontSpec(900, 22);
	const groupLines = wrapText(ctx, options.groupName, INNER_WIDTH);
	const height = CARD_PAD * 2 + 18 + groupLines.length * 27 + 8 + 18 + 20;

	if (draw) {
		ctx.fillStyle = palette.surface;
		roundRectPath(ctx, PAD, y, CONTENT_WIDTH, height, 24);
		ctx.fill();

		let hy = y + CARD_PAD;
		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(800, 11);
		ctx.fillText(brandText, PAD + CARD_PAD, hy + 10);
		hy += 20;

		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(900, 22);
		for (const line of groupLines) {
			ctx.fillText(line, PAD + CARD_PAD, hy + 20);
			hy += 27;
		}
		hy += 6;

		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(600, 12);
		ctx.fillText(options.cycleLabel, PAD + CARD_PAD, hy + 12);
		hy += 20;

		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(800, 13);
		ctx.fillText(
			`${vi.feed.tripTotal}: ${formatMoney(options.totalSpendAmount)}`,
			PAD + CARD_PAD,
			hy + 13,
		);
	}
	return y + height + 12;
}

function drawCaptionBanner({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	if (options.mode !== "reminder" || !options.caption.trim()) return y;
	ctx.font = fontSpec(700, 13);
	const captionLines = wrapText(ctx, options.caption.trim(), INNER_WIDTH);
	const height = CARD_PAD * 2 + captionLines.length * 19;
	if (draw) {
		ctx.fillStyle = palette.accent;
		roundRectPath(ctx, PAD, y, CONTENT_WIDTH, height, 20);
		ctx.fill();

		ctx.fillStyle = palette.onAccent;
		ctx.font = fontSpec(700, 13);
		let cy = y + CARD_PAD;
		for (const line of captionLines) {
			ctx.fillText(line, PAD + CARD_PAD, cy + 13);
			cy += 19;
		}
	}
	return y + height + 12;
}

type SelectedTransfer = BalancesResponse["transfers"][number];

function drawSingleDebtorHero(
	params: SectionParams & { transfer: SelectedTransfer },
): number {
	const { ctx, options, palette, y, draw, transfer } = params;
	const from = options.members.find((m) => m.id === transfer.fromMemberId);
	const to = options.members.find((m) => m.id === transfer.toMemberId);
	const heroHeight = CARD_PAD * 2 + 54;
	if (draw) {
		ctx.fillStyle = palette.surface;
		roundRectPath(ctx, PAD, y, CONTENT_WIDTH, heroHeight, 24);
		ctx.fill();

		if (from) {
			drawMemberShape(
				ctx,
				PAD + CARD_PAD,
				y + CARD_PAD + 8,
				32,
				from.shape,
				from.color,
				palette,
			);
		}
		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(700, 12);
		ctx.fillText(
			`${from?.name ?? vi.activity.someone} → ${to?.name ?? vi.activity.someone}`,
			PAD + CARD_PAD + 42,
			y + CARD_PAD + 16,
		);
		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(900, 26);
		ctx.fillText(
			formatMoney(transfer.amount),
			PAD + CARD_PAD + 42,
			y + CARD_PAD + 46,
		);
	}
	return y + heroHeight + 12;
}

function drawBreakdownAllocation(
	ctx: CanvasRenderingContext2D,
	palette: Palette,
	members: MemberDto[],
	debtorTransfers: SelectedTransfer[],
	selectedTransfer: SelectedTransfer,
	startY: number,
): number {
	const memberName = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;
	let by = startY;
	ctx.fillStyle = palette.border;
	ctx.fillRect(PAD + CARD_PAD, by + 2, INNER_WIDTH, 1);
	by += 10;
	ctx.fillStyle = palette.ink;
	ctx.font = fontSpec(800, 12);
	ctx.fillText(vi.breakdown.transferAllocation, PAD + CARD_PAD, by + 12);
	by += 20;

	for (const item of debtorTransfers) {
		const isCurrent =
			item.fromMemberId === selectedTransfer.fromMemberId &&
			item.toMemberId === selectedTransfer.toMemberId;
		ctx.font = fontSpec(isCurrent ? 800 : 600, 12);
		ctx.fillStyle = isCurrent ? palette.ink : palette.muted;
		const label = `${memberName(item.fromMemberId)} → ${memberName(item.toMemberId)}`;
		const amt = formatMoney(item.amount);
		const amtW = ctx.measureText(amt).width;
		ctx.fillText(label, PAD + CARD_PAD, by + 12);
		ctx.fillText(amt, PAD + CARD_PAD + INNER_WIDTH - amtW, by + 12);
		by += 22;
	}
	return by;
}

function drawSingleDebtorBreakdown(
	params: SectionParams & { transfer: SelectedTransfer },
): number {
	const { ctx, options, palette, y, draw, transfer } = params;
	const breakdown = options.breakdowns.find(
		(b) => b.memberId === transfer.fromMemberId,
	);
	if (!breakdown) return y;

	const visibleLines = breakdown.lines.slice(0, 12);
	const extraCount = Math.max(0, breakdown.lines.length - visibleLines.length);
	const debtorTransfers = options.transfers.filter(
		(t) => t.fromMemberId === transfer.fromMemberId,
	);
	const showAllocation =
		debtorTransfers.length > 1 ||
		Math.abs(breakdown.netBalance) !== transfer.amount;

	let boxHeight = CARD_PAD * 2 + 24 + visibleLines.length * 24 + 28;
	if (breakdown.carryOverBalance !== 0) boxHeight += 22;
	if (extraCount > 0) boxHeight += 20;
	if (showAllocation) boxHeight += 28 + debtorTransfers.length * 22;

	if (!draw) return y + boxHeight + 12;

	ctx.fillStyle = palette.surface;
	roundRectPath(ctx, PAD, y, CONTENT_WIDTH, boxHeight, 24);
	ctx.fill();

	let by = y + CARD_PAD;
	ctx.fillStyle = palette.ink;
	ctx.font = fontSpec(800, 13);
	ctx.fillText(vi.breakdown.title, PAD + CARD_PAD, by + 13);
	by += 24;

	if (breakdown.carryOverBalance !== 0) {
		ctx.font = fontSpec(600, 12);
		ctx.fillStyle = palette.muted;
		ctx.fillText(vi.breakdown.carryOver, PAD + CARD_PAD, by + 12);
		const valText = `${formatSignedAmount(breakdown.carryOverBalance)} ${vi.common.currency}`;
		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(700, 12);
		const valW = ctx.measureText(valText).width;
		ctx.fillText(valText, PAD + CARD_PAD + INNER_WIDTH - valW, by + 12);
		by += 22;
	}

	for (const line of visibleLines) {
		const valText = `${formatSignedAmount(line.delta)} ${vi.common.currency}`;
		ctx.font = fontSpec(700, 12);
		const valW = ctx.measureText(valText).width;
		ctx.fillStyle = line.delta >= 0 ? palette.credit : palette.debt;
		ctx.fillText(valText, PAD + CARD_PAD + INNER_WIDTH - valW, by + 12);

		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(600, 12);
		const prefix = `${formatShortDate(line.occurredAt)} · ${line.description}`;
		ctx.fillText(
			clipText(ctx, prefix, INNER_WIDTH - valW - 12),
			PAD + CARD_PAD,
			by + 12,
		);
		by += 24;
	}

	if (extraCount > 0) {
		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(600, 11);
		ctx.fillText(`+${extraCount}`, PAD + CARD_PAD, by + 11);
		by += 20;
	}

	ctx.fillStyle = palette.border;
	ctx.fillRect(PAD + CARD_PAD, by + 2, INNER_WIDTH, 1);
	by += 10;

	ctx.fillStyle = palette.ink;
	ctx.font = fontSpec(800, 13);
	ctx.fillText(vi.breakdown.currentBalance, PAD + CARD_PAD, by + 13);
	const netText = `${formatSignedAmount(breakdown.netBalance)} ${vi.common.currency}`;
	const netW = ctx.measureText(netText).width;
	ctx.fillText(netText, PAD + CARD_PAD + INNER_WIDTH - netW, by + 13);
	by += 22;

	if (showAllocation) {
		drawBreakdownAllocation(
			ctx,
			palette,
			options.members,
			debtorTransfers,
			transfer,
			by,
		);
	}
	return y + boxHeight + 12;
}

function drawSingleDebtorPayBox(
	params: SectionParams & { transfer: SelectedTransfer },
): number {
	const { ctx, palette, y, draw, transfer } = params;
	const bank = transfer.payTo.find((m) => m.kind === "bank");
	const wallets = transfer.payTo.filter((m) => m.kind !== "bank");
	if (!bank && wallets.length === 0) return y;

	const qrSize = bank?.qrPayload ? 168 : 0;
	const payBoxHeight =
		CARD_PAD * 2 +
		(qrSize > 0 ? qrSize + 14 : 0) +
		(bank ? 4 : 0) * 19 +
		wallets.length * 19 +
		4;

	if (!draw) return y + payBoxHeight + 12;

	ctx.fillStyle = palette.surface;
	roundRectPath(ctx, PAD, y, CONTENT_WIDTH, payBoxHeight, 24);
	ctx.fill();

	let py = y + CARD_PAD;
	if (bank?.qrPayload) {
		drawQrBox(
			ctx,
			PAD + (CONTENT_WIDTH - qrSize) / 2,
			py,
			qrSize,
			bank.qrPayload,
		);
		py += qrSize + 14;
	}
	ctx.fillStyle = palette.ink;
	ctx.font = fontSpec(700, 12);
	if (bank) {
		for (const line of [
			`${vi.payment.bank}: ${bank.bankShortName}`,
			`${vi.payment.accountNumber}: ${bank.accountNumber}`,
			`${vi.payment.accountName}: ${bank.accountName}`,
			`${vi.pay.purpose}: ${transfer.purpose}`,
		]) {
			ctx.fillText(line, PAD + CARD_PAD, py + 12);
			py += 19;
		}
	}
	for (const wallet of wallets) {
		const label =
			wallet.kind === "momo"
				? `MoMo: ${wallet.phone}`
				: `ZaloPay: ${wallet.phone}`;
		ctx.fillText(label, PAD + CARD_PAD, py + 12);
		py += 19;
	}
	return y + payBoxHeight + 12;
}

function drawTransfersListSection({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	const rowCount = options.transfers.length;
	const listHeight =
		rowCount === 0 ? CARD_PAD * 2 + 28 : CARD_PAD * 2 + 26 + rowCount * 34;

	if (!draw) return y + listHeight + 12;

	ctx.fillStyle = palette.surface;
	roundRectPath(ctx, PAD, y, CONTENT_WIDTH, listHeight, 24);
	ctx.fill();

	let ly = y + CARD_PAD;
	if (rowCount === 0) {
		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(800, 14);
		ctx.fillText(vi.balances.allSettledTitle, PAD + CARD_PAD, ly + 16);
		return y + listHeight + 12;
	}

	ctx.fillStyle = palette.muted;
	ctx.font = fontSpec(800, 12);
	ctx.fillText(
		vi.balances.headline.replace("{count}", String(rowCount)),
		PAD + CARD_PAD,
		ly + 12,
	);
	ly += 26;

	for (const transfer of options.transfers) {
		const from = options.members.find((m) => m.id === transfer.fromMemberId);
		const to = options.members.find((m) => m.id === transfer.toMemberId);
		if (from) {
			drawMemberShape(
				ctx,
				PAD + CARD_PAD,
				ly + 2,
				22,
				from.shape,
				from.color,
				palette,
			);
		}
		const amtText = formatMoney(transfer.amount);
		ctx.font = fontSpec(800, 13);
		const amtW = ctx.measureText(amtText).width;
		ctx.fillStyle = palette.ink;
		ctx.fillText(amtText, PAD + CARD_PAD + INNER_WIDTH - amtW, ly + 17);

		ctx.font = fontSpec(700, 13);
		const label = `${from?.name ?? vi.activity.someone} → ${to?.name ?? vi.activity.someone}`;
		ctx.fillText(
			clipText(ctx, label, INNER_WIDTH - 30 - amtW - 10),
			PAD + CARD_PAD + 30,
			ly + 17,
		);
		ly += 34;
	}
	return y + listHeight + 12;
}

function drawExpenseDigestSection({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	if (
		options.mode !== "summary" ||
		!options.includeExpenses ||
		options.expenses.length === 0
	) {
		return y;
	}
	const visibleExpenses = options.expenses.slice(0, 15);
	const remainingCount = Math.max(
		0,
		options.expenses.length - visibleExpenses.length,
	);
	const digestHeight =
		CARD_PAD * 2 +
		24 +
		visibleExpenses.length * 24 +
		(remainingCount > 0 ? 20 : 0);

	if (!draw) return y + digestHeight + 12;

	ctx.fillStyle = palette.surface;
	roundRectPath(ctx, PAD, y, CONTENT_WIDTH, digestHeight, 24);
	ctx.fill();

	let ey = y + CARD_PAD;
	ctx.fillStyle = palette.muted;
	ctx.font = fontSpec(800, 12);
	ctx.fillText(vi.groupSegments.expenses, PAD + CARD_PAD, ey + 12);
	ey += 24;

	for (const expense of visibleExpenses) {
		const amtText = formatMoney(expense.amount);
		ctx.font = fontSpec(700, 12);
		const amtW = ctx.measureText(amtText).width;
		ctx.fillStyle = palette.ink;
		ctx.fillText(amtText, PAD + CARD_PAD + INNER_WIDTH - amtW, ey + 12);

		ctx.font = fontSpec(600, 12);
		ctx.fillStyle = palette.muted;
		const text = `${formatShortDate(expense.occurredAt)} · ${expense.description}`;
		ctx.fillText(
			clipText(ctx, text, INNER_WIDTH - amtW - 10),
			PAD + CARD_PAD,
			ey + 12,
		);
		ey += 24;
	}
	if (remainingCount > 0) {
		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(600, 11);
		ctx.fillText(`+${remainingCount}`, PAD + CARD_PAD, ey + 11);
	}
	return y + digestHeight + 12;
}

function drawReceiverFooterSection({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	const receivers = collectReceivers(options.transfers, options.members);
	if (receivers.length === 0) return y;

	if (receivers.length === 1 && receivers[0]?.bank?.accountQrPayload) {
		const receiver = receivers[0];
		const bank = receiver.bank;
		if (!bank?.accountQrPayload) return y;
		const qrSize = 156;
		const footerHeight = CARD_PAD * 2 + qrSize + 14 + 58;
		if (!draw) return y + footerHeight + 12;

		ctx.fillStyle = palette.surface;
		roundRectPath(ctx, PAD, y, CONTENT_WIDTH, footerHeight, 24);
		ctx.fill();

		let fy = y + CARD_PAD;
		drawQrBox(
			ctx,
			PAD + (CONTENT_WIDTH - qrSize) / 2,
			fy,
			qrSize,
			bank.accountQrPayload,
		);
		fy += qrSize + 14;
		ctx.fillStyle = palette.ink;
		ctx.font = fontSpec(700, 12);
		ctx.fillText(
			`${bank.bankShortName} · ${bank.accountNumber}`,
			PAD + CARD_PAD,
			fy + 12,
		);
		fy += 19;
		ctx.fillText(bank.accountName, PAD + CARD_PAD, fy + 12);
		fy += 19;
		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(600, 11);
		ctx.fillText(receiver.memberName, PAD + CARD_PAD, fy + 11);
		return y + footerHeight + 12;
	}

	const footerHeight = CARD_PAD * 2 + 22 + receivers.length * 22;
	if (!draw) return y + footerHeight + 12;

	ctx.fillStyle = palette.surface;
	roundRectPath(ctx, PAD, y, CONTENT_WIDTH, footerHeight, 24);
	ctx.fill();

	let fy = y + CARD_PAD;
	ctx.fillStyle = palette.muted;
	ctx.font = fontSpec(800, 12);
	ctx.fillText(vi.payment.title, PAD + CARD_PAD, fy + 12);
	fy += 22;

	ctx.fillStyle = palette.ink;
	ctx.font = fontSpec(600, 12);
	for (const receiver of receivers) {
		const summary = receiver.bank
			? `${receiver.memberName}: ${receiver.bank.bankShortName} ${receiver.bank.accountNumber}`
			: receiver.wallets[0]
				? `${receiver.memberName}: ${receiver.wallets[0].kind === "momo" ? "MoMo" : "ZaloPay"} ${receiver.wallets[0].phone}`
				: receiver.memberName;
		ctx.fillText(clipText(ctx, summary, INNER_WIDTH), PAD + CARD_PAD, fy + 12);
		fy += 22;
	}
	return y + footerHeight + 12;
}

function drawGuestLinkSection({
	ctx,
	options,
	palette,
	y,
	draw,
}: SectionParams): number {
	if (!options.guestLinkUrl) return y;
	ctx.font = fontSpec(600, 11);
	const linkLines = wrapText(
		ctx,
		`${vi.guestLink.title}: ${options.guestLinkUrl}`,
		INNER_WIDTH,
	);
	const linkBoxHeight = CARD_PAD * 2 + linkLines.length * 16;
	if (draw) {
		ctx.fillStyle = palette.sunken;
		roundRectPath(ctx, PAD, y, CONTENT_WIDTH, linkBoxHeight, 18);
		ctx.fill();

		ctx.fillStyle = palette.muted;
		ctx.font = fontSpec(600, 11);
		let ly = y + CARD_PAD;
		for (const line of linkLines) {
			ctx.fillText(line, PAD + CARD_PAD, ly + 11);
			ly += 16;
		}
	}
	return y + linkBoxHeight + 12;
}

function renderPass(
	ctx: CanvasRenderingContext2D,
	options: ShareCardRenderOptions,
	palette: Palette,
	draw: boolean,
): number {
	const selectedTransfer =
		options.mode === "reminder" && options.targetTransferKey !== "all"
			? (options.transfers.find(
					(t) =>
						`${t.fromMemberId}-${t.toMemberId}` === options.targetTransferKey,
				) ?? null)
			: null;

	let y = PAD;
	y = drawHeaderSection({ ctx, options, palette, y, draw });
	y = drawCaptionBanner({ ctx, options, palette, y, draw });
	if (selectedTransfer) {
		y = drawSingleDebtorHero({
			ctx,
			options,
			palette,
			y,
			draw,
			transfer: selectedTransfer,
		});
		y = drawSingleDebtorBreakdown({
			ctx,
			options,
			palette,
			y,
			draw,
			transfer: selectedTransfer,
		});
		y = drawSingleDebtorPayBox({
			ctx,
			options,
			palette,
			y,
			draw,
			transfer: selectedTransfer,
		});
	} else {
		y = drawTransfersListSection({ ctx, options, palette, y, draw });
		y = drawExpenseDigestSection({ ctx, options, palette, y, draw });
		y = drawReceiverFooterSection({ ctx, options, palette, y, draw });
	}
	y = drawGuestLinkSection({ ctx, options, palette, y, draw });
	return y + PAD - 12;
}

export async function renderShareCardPng(
	options: ShareCardRenderOptions,
): Promise<Blob> {
	if (typeof document !== "undefined" && "fonts" in document) {
		await document.fonts.ready;
	}
	const palette = PALETTES[options.theme];
	const measureCanvas = document.createElement("canvas");
	measureCanvas.width = LOGICAL_WIDTH;
	measureCanvas.height = 100;
	const measureCtx = measureCanvas.getContext("2d");
	if (!measureCtx) {
		throw new Error("Canvas 2D context unavailable");
	}
	const totalHeight = Math.ceil(
		renderPass(measureCtx, options, palette, false),
	);

	const canvas = document.createElement("canvas");
	canvas.width = LOGICAL_WIDTH * SCALE;
	canvas.height = totalHeight * SCALE;
	const ctx = canvas.getContext("2d");
	if (!ctx) {
		throw new Error("Canvas 2D context unavailable");
	}
	ctx.scale(SCALE, SCALE);
	ctx.fillStyle = palette.bg;
	ctx.fillRect(0, 0, LOGICAL_WIDTH, totalHeight);
	renderPass(ctx, options, palette, true);

	return await new Promise<Blob>((resolve, reject) => {
		canvas.toBlob((blob) => {
			if (blob) resolve(blob);
			else reject(new Error("Share card PNG encoding failed"));
		}, "image/png");
	});
}
