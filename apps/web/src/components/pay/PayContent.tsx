"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { ScreenHeader } from "../ui/ScreenHeader";
import { CopyRow } from "./CopyRow";
import { PayFooter } from "./PayFooter";
import { PayMethodsCard } from "./PayMethodsCard";

type Transfer = BalancesResponse["transfers"][number];
const MAX_TRANSFER_AMOUNT = 999_999_999_999;

export function PayContent({
	groupId,
	from,
	to,
	transfer,
	myMemberId,
	role,
	verified,
}: {
	groupId: string;
	from: MemberDto;
	to: MemberDto;
	transfer: Transfer;
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
}) {
	const mayCreate = role !== "viewer" || myMemberId === from.id;
	const canEdit = verified && role !== "viewer";
	const canAddDetails = verified && (role !== "viewer" || myMemberId === to.id);
	const canResolve =
		role === "owner" ||
		myMemberId === to.id ||
		(role === "editor" && !to.claimed);
	const canCancel =
		Boolean(transfer.pendingRequest?.createdByMe) || myMemberId === from.id;
	const payAmount = Math.min(transfer.amount, MAX_TRANSFER_AMOUNT);
	const isPartial = transfer.amount > MAX_TRANSFER_AMOUNT;

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6 pb-28">
			<ScreenHeader
				title={t(vi.pay.title, { to: to.name })}
				backHref={`/g/${groupId}/balances`}
				backLabel={vi.common.back}
			/>
			<div className="flex items-center justify-around rounded-[36px] bg-surface p-4">
				{[from, to].map((member, index) => (
					<div key={member.id} className="flex items-center gap-3">
						<div className="grid justify-items-center gap-2">
							<MemberShape {...member} size={56} />
							<span className="text-sm font-extrabold">
								{member.id === myMemberId ? vi.common.you : member.name}
							</span>
						</div>
						{index === 0 && <Icon name="arrow-right" size={20} />}
					</div>
				))}
			</div>
			<div className="grid justify-items-center gap-2 text-center">
				<p className="text-[40px] font-black tracking-tight">
					{formatMoney(payAmount)}
				</p>
				<CopyRow
					label={vi.pay.copyAmount}
					value={formatMoney(payAmount)}
					copyValue={String(payAmount)}
					buttonLabel={vi.pay.copyAmount}
					compact
				/>
				{isPartial && (
					<p className="text-xs font-semibold text-muted">
						{t(vi.pay.partialNote, {
							amount: formatMoney(payAmount),
							total: formatMoney(transfer.amount),
						})}
					</p>
				)}
			</div>
			<PayMethodsCard
				groupId={groupId}
				transfer={transfer}
				toName={to.name}
				canAddDetails={canAddDetails}
			/>
			<PayFooter
				groupId={groupId}
				from={from}
				to={to}
				transfer={transfer}
				payAmount={payAmount}
				mayCreate={mayCreate}
				canEdit={canEdit}
				canResolve={canResolve}
				canCancel={canCancel}
				verified={verified}
			/>
		</main>
	);
}
