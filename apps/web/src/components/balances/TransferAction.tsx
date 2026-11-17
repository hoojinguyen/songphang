"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { payHref, settlementHref } from "../../lib/balances";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
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
}: {
	groupId: string;
	transfer: BalancesResponse["transfers"][number];
	from: MemberDto;
	to: MemberDto;
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
	compact?: boolean;
}) {
	if (transfer.pendingRequest) {
		const canResolve =
			role === "owner" ||
			myMemberId === to.id ||
			(role === "editor" && !to.claimed);
		const canCancel =
			transfer.pendingRequest.createdByMe || myMemberId === from.id;
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
						? "flex min-h-11 items-center rounded-pill bg-sunken px-3 text-xs font-bold"
						: "flex min-h-[60px] w-full items-center justify-center rounded-[30px] bg-accent font-extrabold"
				}
			>
				{vi.balances.record}
			</OnlineLink>
		);
	}
	const label =
		from.id === myMemberId
			? vi.feed.pay
			: role !== "viewer"
				? vi.balances.record
				: vi.feed.view;
	return (
		<OnlineLink
			href={payHref(groupId, transfer)}
			className={
				compact
					? "flex min-h-11 items-center rounded-pill bg-sunken px-3 text-xs font-bold"
					: "flex min-h-[60px] w-full items-center justify-center rounded-[30px] bg-accent font-extrabold"
			}
		>
			{label}
		</OnlineLink>
	);
}
