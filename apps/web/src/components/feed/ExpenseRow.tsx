import type {
	CategoryDto,
	MemberDto,
	TransactionDto,
} from "@songphang/contract";
import {
	formatAmount,
	formatCompactAmount,
	formatMoney,
} from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { CATEGORY_COLORS } from "../settings/CategoryRow";
import { MemberShape } from "../ui/MemberShape";
export function ExpenseRow({
	transaction,
	members,
	categories = [],
	myMemberId,
}: {
	transaction: TransactionDto;
	members: MemberDto[];
	categories?: CategoryDto[];
	myMemberId: string | null;
}) {
	const customCategory = transaction.categoryId
		? categories.find((category) => category.id === transaction.categoryId)
		: undefined;
	const categoryLabel = transaction.category
		? vi.expenseForm.categories[transaction.category]
		: customCategory?.name;
	const payer = members.find(
		(member) => member.id === transaction.payers[0]?.memberId,
	);
	const isMine = transaction.payers.some(
		(entry) => entry.memberId === myMemberId,
	);
	const payerLine = transaction.payers
		.map((entry) => {
			const member = members.find((member) => member.id === entry.memberId);
			const label =
				entry.memberId === myMemberId
					? vi.feed.youPaid
					: t(vi.feed.memberPaid, {
							name: member?.name ?? vi.activity.someone,
						});
			return `${label} ${formatMoney(entry.amount)}`;
		})
		.join(" · ");
	const method = transaction.split.method;
	const methodLabel =
		method === "exact"
			? vi.feed.splitExact
			: method === "shares"
				? vi.feed.splitShares
				: vi.feed.splitPercent;
	const myShare = transaction.shares.find(
		(share) => share.memberId === myMemberId,
	);
	return (
		<div
			className={`flex items-end gap-2 ${isMine ? "justify-end" : "justify-start"}`}
		>
			{!isMine && payer && <MemberShape {...payer} size={36} />}
			<div
				className={`min-w-0 px-4 pb-[14px] pt-3 ${isMine ? "max-w-[300px] rounded-[26px] rounded-br-[8px] bg-ink text-surface" : "max-w-[270px] rounded-[26px] rounded-bl-[8px] bg-surface"}`}
			>
				<p
					className={`text-xs font-semibold ${isMine ? "text-on-ink-muted" : "text-muted"}`}
				>
					{transaction.payers.length > 1
						? payerLine
						: isMine
							? vi.feed.youPaid
							: t(vi.feed.memberPaid, {
									name: payer?.name ?? vi.activity.someone,
								})}
				</p>
				<div className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
					<p className="min-w-0 break-words text-[15px] font-bold">
						{transaction.description}
					</p>
					<p className="text-[19px] font-black">
						{formatAmount(transaction.amount)}
					</p>
				</div>
				{(categoryLabel || transaction.version > 1) && (
					<div
						className={`mt-1 flex flex-wrap items-center gap-2 text-[11px] font-bold ${isMine ? "text-on-ink-muted" : "text-muted"}`}
					>
						{categoryLabel && (
							<span className="inline-flex items-center gap-1.5">
								{customCategory && (
									<span
										aria-hidden="true"
										className={`h-2.5 w-2.5 shrink-0 rounded-full ${CATEGORY_COLORS[customCategory.color].bg}`}
									/>
								)}
								<span>{categoryLabel}</span>
							</span>
						)}
						{transaction.version > 1 && <span>{vi.feed.edited}</span>}
					</div>
				)}
				{isMine && (
					<div className="mt-2 flex flex-wrap gap-1">
						{transaction.shares.slice(0, 4).map((share) => {
							const member = members.find(
								(member) => member.id === share.memberId,
							);
							return (
								<span
									key={share.memberId}
									className="flex items-center gap-1 rounded-[14px] bg-ink-raised px-[9px] py-[5px] text-xs font-bold"
								>
									{member && <MemberShape {...member} size={14} />}
									<span>{formatCompactAmount(share.amount)}</span>
								</span>
							);
						})}
						{transaction.shares.length > 4 && (
							<span className="px-2 py-1 text-xs">
								{t(vi.feed.moreShares, {
									count: String(transaction.shares.length - 4),
								})}
							</span>
						)}
					</div>
				)}
				{(!isMine || transaction.payers.length > 1) && (
					<p
						className={`mt-1 text-[13px] ${isMine ? "text-on-ink-muted" : "text-muted"}`}
					>
						{myShare
							? t(
									method === "equal"
										? vi.feed.equalSplitMine
										: vi.feed.splitMine,
									{
										method: methodLabel,
										count: String(transaction.shares.length),
										amount: formatAmount(myShare.amount),
									},
								)
							: t(
									method === "equal"
										? vi.feed.equalSplitNotMine
										: vi.feed.splitNotMine,
									{
										method: methodLabel,
										count: String(transaction.shares.length),
									},
								)}
					</p>
				)}
			</div>
		</div>
	);
}
