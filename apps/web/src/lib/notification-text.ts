import { type NotificationDto, NotificationPayload } from "@songphang/contract";
import { t, vi } from "../messages/vi";
import { formatMoney } from "./money";

export function notificationText(dto: NotificationDto): {
	text: string;
	href: string;
} {
	const parsed = NotificationPayload.safeParse(dto.payload);
	if (!parsed.success) {
		const rawGroup = dto.payload.groupName;
		return {
			text: t(vi.notifications.fallback, {
				group: typeof rawGroup === "string" ? rawGroup : "",
			}),
			href: `/g/${dto.groupId}`,
		};
	}
	const p = parsed.data;
	const txHref = () =>
		"transactionId" in p
			? `/g/${dto.groupId}/tx/${p.transactionId}/view`
			: `/g/${dto.groupId}`;
	switch (p.kind) {
		case "expense_added":
			return {
				text: t(vi.notifications.expenseAdded, {
					actor: p.actorName,
					description: p.description,
					share: formatMoney(p.share),
				}),
				href: txHref(),
			};
		case "expense_changed":
			return {
				text: t(
					p.action === "deleted"
						? vi.notifications.expenseDeleted
						: vi.notifications.expenseEdited,
					{ actor: p.actorName, description: p.description },
				),
				href: txHref(),
			};
		case "comment_added":
			return {
				text: t(vi.notifications.commentAdded, {
					actor: p.actorName,
					description: p.description,
				}),
				href: txHref(),
			};
		case "dispute_opened":
			return {
				text: t(vi.notifications.disputeOpened, {
					actor: p.actorName,
					description: p.description,
				}),
				href: txHref(),
			};
		case "dispute_resolved":
			return {
				text: t(vi.notifications.disputeResolved, {
					actor: p.actorName,
					description: p.description,
				}),
				href: txHref(),
			};
		case "settlement_requested":
			return {
				text: t(vi.notifications.settlementRequested, {
					actor: p.actorName,
					amount: formatMoney(p.amount),
				}),
				href: `/g/${dto.groupId}/balances`,
			};
		case "settlement_confirmed":
			return {
				text: t(vi.notifications.settlementConfirmed, {
					actor: p.actorName,
					amount: formatMoney(p.amount),
				}),
				href: `/g/${dto.groupId}/balances`,
			};
		case "settlement_rejected":
			return {
				text: t(vi.notifications.settlementRejected, {
					actor: p.actorName,
					amount: formatMoney(p.amount),
				}),
				href: `/g/${dto.groupId}/balances`,
			};
		case "debt_reminder":
			return {
				text: t(vi.notifications.debtReminder, {
					to: p.toName,
					amount: formatMoney(p.amount),
					group: p.groupName,
				}),
				href: `/g/${dto.groupId}/balances`,
			};
		case "approval_requested":
			return {
				text: t(vi.notifications.approvalRequested, {
					actor: p.actorName,
					description: p.description,
					amount: formatMoney(p.amount),
				}),
				href: txHref(),
			};
		case "approval_decided":
			return {
				text: t(
					p.decision === "approved"
						? vi.notifications.approvalApproved
						: vi.notifications.approvalRejected,
					{ actor: p.actorName, description: p.description },
				),
				href: txHref(),
			};
		case "budget_state":
			return {
				text: t(
					p.state === "over"
						? vi.notifications.budgetOver
						: vi.notifications.budgetNear,
					{ group: p.groupName },
				),
				href: `/g/${dto.groupId}/stats`,
			};
	}
}
