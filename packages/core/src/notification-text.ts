import { formatMoney } from "./money.ts";

function asString(value: unknown): string {
	return typeof value === "string" ? value : "";
}

function asNonNegativeInt(value: unknown): number | null {
	return typeof value === "number" && Number.isInteger(value) && value >= 0
		? value
		: null;
}

function asPositiveInt(value: unknown): number | null {
	return typeof value === "number" && Number.isInteger(value) && value > 0
		? value
		: null;
}

function isObjectRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function formatNotificationText(dto: {
	groupId: string;
	kind: string;
	payload: unknown;
}): { text: string; href: string } {
	const fallbackGroup =
		isObjectRecord(dto.payload) && typeof dto.payload.groupName === "string"
			? dto.payload.groupName
			: "";
	const fallback = {
		text: `Có cập nhật trong nhóm ${fallbackGroup}`,
		href: `/g/${dto.groupId}`,
	};
	if (!isObjectRecord(dto.payload)) return fallback;
	const p = dto.payload;
	const kind = typeof p.kind === "string" ? p.kind : dto.kind;
	const actor = asString(p.actorName);
	const group = asString(p.groupName);
	const description = asString(p.description);
	const transactionId = asString(p.transactionId);
	const txHref = transactionId
		? `/g/${dto.groupId}/tx/${transactionId}/view`
		: `/g/${dto.groupId}`;

	switch (kind) {
		case "expense_added": {
			const share = asNonNegativeInt(p.share);
			if (!transactionId || share === null) return fallback;
			return {
				text: `${actor} thêm ${description} · phần bạn ${formatMoney(share)}`,
				href: txHref,
			};
		}
		case "expense_changed":
			if (!transactionId) return fallback;
			if (p.action !== "deleted" && p.action !== "edited") return fallback;
			return {
				text:
					p.action === "deleted"
						? `${actor} đã xoá ${description}`
						: `${actor} đã sửa ${description}`,
				href: txHref,
			};
		case "comment_added":
			if (!transactionId) return fallback;
			return { text: `${actor} bình luận về ${description}`, href: txHref };
		case "dispute_opened":
			if (!transactionId) return fallback;
			return {
				text: `${actor} cho rằng ${description} chưa đúng`,
				href: txHref,
			};
		case "dispute_resolved":
			if (!transactionId) return fallback;
			return { text: `${actor} đã giải quyết ${description}`, href: txHref };
		case "settlement_requested": {
			const amount = asPositiveInt(p.amount);
			if (amount === null) return fallback;
			return {
				text: `${actor} báo đã chuyển cho bạn ${formatMoney(amount)}`,
				href: `/g/${dto.groupId}/balances`,
			};
		}
		case "settlement_confirmed": {
			const amount = asPositiveInt(p.amount);
			if (amount === null) return fallback;
			return {
				text: `${actor} đã xác nhận nhận ${formatMoney(amount)}`,
				href: `/g/${dto.groupId}/balances`,
			};
		}
		case "settlement_rejected": {
			const amount = asPositiveInt(p.amount);
			if (amount === null) return fallback;
			return {
				text: `${actor} báo chưa nhận được ${formatMoney(amount)}`,
				href: `/g/${dto.groupId}/balances`,
			};
		}
		case "debt_reminder": {
			const amount = asPositiveInt(p.amount);
			if (amount === null) return fallback;
			return {
				text: `Nhắc nhẹ: bạn cần trả ${asString(p.toName)} ${formatMoney(amount)} trong nhóm ${group}`,
				href: `/g/${dto.groupId}/balances`,
			};
		}
		case "approval_requested": {
			const amount = asPositiveInt(p.amount);
			if (!transactionId || amount === null) return fallback;
			return {
				text: `${actor} thêm ${description} · ${formatMoney(amount)}, cần bạn duyệt`,
				href: txHref,
			};
		}
		case "approval_decided":
			if (!transactionId) return fallback;
			if (p.decision !== "approved" && p.decision !== "rejected") {
				return fallback;
			}
			return {
				text:
					p.decision === "approved"
						? `${actor} đã duyệt ${description}`
						: `${actor} không duyệt ${description}`,
				href: txHref,
			};
		case "budget_state":
			if (p.state !== "over" && p.state !== "near") return fallback;
			return {
				text:
					p.state === "over"
						? `Nhóm ${group} đã vượt hạn mức`
						: `Nhóm ${group} sắp chạm hạn mức`,
				href: `/g/${dto.groupId}/stats`,
			};
		default:
			return fallback;
	}
}
