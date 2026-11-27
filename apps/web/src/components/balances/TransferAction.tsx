"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { ApiError } from "../../lib/api";
import { payHref, settlementHref } from "../../lib/balances";
import { formatMoney } from "../../lib/money";
import {
	canRemindTransfer,
	formatReminderNextAt,
	useSendReminder,
} from "../../lib/reminders";
import { t, vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
import { OnlineLink } from "../ui/OnlineLink";
import { PendingRequestRow } from "./PendingRequestRow";

export function fundTransferCaption(
	from: MemberDto,
	to: MemberDto,
	amount: number,
): string | null {
	if (from.kind === "fund")
		return t(vi.balances.fundRefundsMember, {
			to: to.name,
			amount: formatMoney(amount),
		});
	if (to.kind === "fund")
		return t(vi.balances.memberContributesToFund, {
			from: from.name,
			amount: formatMoney(amount),
		});
	return null;
}

export function TransferAction({
	groupId,
	transfer,
	from,
	to,
	myMemberId,
	role,
	verified,
	compact = false,
	onRemindNotice,
}: {
	groupId: string;
	transfer: BalancesResponse["transfers"][number];
	from: MemberDto;
	to: MemberDto;
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
	compact?: boolean;
	onRemindNotice?: (message: string) => void;
}) {
	const sendReminder = useSendReminder(groupId);
	const isFromSide =
		myMemberId !== null &&
		(myMemberId === from.id ||
			Boolean(transfer.fromHousehold?.memberIds.includes(myMemberId)));
	if (transfer.pendingRequest) {
		const canResolve =
			role === "owner" ||
			myMemberId === to.id ||
			(role === "editor" && !to.claimed);
		const canCancel = transfer.pendingRequest.createdByMe || isFromSide;
		return (
			<PendingRequestRow
				groupId={groupId}
				request={transfer.pendingRequest}
				fromName={from.name}
				toName={to.name}
				canResolve={canResolve}
				canCancel={canCancel}
				verified={verified}
			/>
		);
	}
	if (from.kind === "fund" || to.kind === "fund") {
		if (role === "viewer" || !verified) return null;
		return (
			<OnlineLink
				href={settlementHref(groupId, transfer)}
				className={
					compact
						? "flex min-h-11 items-center rounded-pill bg-sunken px-3 text-xs font-bold text-ink"
						: "flex min-h-[60px] w-full items-center justify-center rounded-[30px] bg-accent font-extrabold text-on-accent"
				}
			>
				{vi.balances.record}
			</OnlineLink>
		);
	}
	const label = isFromSide
		? vi.feed.pay
		: role !== "viewer"
			? vi.balances.record
			: vi.feed.view;
	const showRemind = canRemindTransfer({
		transfer,
		from,
		to,
		myMemberId,
		role,
		verified,
	});
	const handleRemind = async () => {
		try {
			await sendReminder.mutateAsync({
				fromMemberId: from.id,
				toMemberId: to.id,
			});
			onRemindNotice?.(t(vi.reminders.remindedOne, { name: from.name }));
		} catch (error) {
			if (
				error instanceof ApiError &&
				error.code === "REMINDER_TOO_SOON" &&
				typeof error.details?.nextAt === "string"
			) {
				onRemindNotice?.(
					t(vi.reminders.tooSoon, {
						name: from.name,
						time: formatReminderNextAt(error.details.nextAt),
					}),
				);
			} else {
				onRemindNotice?.(vi.common.saveError);
			}
		}
	};
	return (
		<div className={compact ? "flex items-center gap-2" : "flex gap-2"}>
			<OnlineLink
				href={payHref(groupId, transfer)}
				className={
					compact
						? "flex min-h-11 items-center rounded-pill bg-sunken px-3 text-xs font-bold text-ink"
						: "flex min-h-[60px] flex-1 items-center justify-center rounded-[30px] bg-accent font-extrabold text-on-accent"
				}
			>
				{label}
			</OnlineLink>
			{showRemind && (
				<OnlineButton
					type="button"
					disabled={sendReminder.isPending}
					onClick={() => {
						void handleRemind();
					}}
					className={
						compact
							? "flex min-h-11 shrink-0 items-center rounded-pill bg-sunken px-3 text-xs font-bold text-ink disabled:opacity-60"
							: "flex min-h-[60px] shrink-0 items-center justify-center rounded-[30px] bg-sunken px-5 font-bold text-ink disabled:opacity-60"
					}
				>
					{vi.reminders.remind}
				</OnlineButton>
			)}
		</div>
	);
}
