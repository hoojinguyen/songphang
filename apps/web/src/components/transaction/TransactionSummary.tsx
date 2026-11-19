import type {
	CategoryDto,
	MemberDto,
	TransactionDto,
} from "@songphang/contract";
import { formatVietnamDateTime } from "@songphang/core";
import { formatAmount, formatCompactAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { PhotoRow } from "../expense-form/PhotoRow";
import { ShareShapes } from "../quick-entry/ShareShapes";
import { CATEGORY_COLORS } from "../settings/CategoryRow";

export function TransactionSummary({
	groupId,
	transaction,
	members,
	categories,
}: {
	groupId: string;
	transaction: TransactionDto;
	members: MemberDto[];
	categories: CategoryDto[];
}) {
	const name = (id: string) => members.find((m) => m.id === id)?.name ?? "";
	const customCategory = transaction.categoryId
		? categories.find((c) => c.id === transaction.categoryId)
		: undefined;
	const categoryLabel = transaction.category
		? vi.expenseForm.categories[transaction.category]
		: customCategory
			? customCategory.archived
				? `${customCategory.name} (${vi.categories.archivedTag})`
				: customCategory.name
			: null;
	const equal =
		transaction.shares.length > 0 &&
		transaction.shares.every((s) => s.amount === transaction.shares[0]?.amount);
	const payerNames = transaction.payers
		.map((p) =>
			transaction.payers.length > 1
				? `${name(p.memberId)} ${formatCompactAmount(p.amount)}`
				: name(p.memberId),
		)
		.join(" · ");

	return (
		<section className="grid gap-4 rounded-[40px] bg-surface px-[18px] pb-[18px] pt-5">
			{transaction.deletedAt && (
				<p role="status" className="text-xs font-bold text-muted">
					{vi.expenseForm.deletedNotice}
				</p>
			)}
			<div className="flex items-center justify-between gap-2 text-xs font-semibold text-muted">
				<span>{formatVietnamDateTime(new Date(transaction.occurredAt))}</span>
				{transaction.version > 1 && <span>{vi.feed.edited}</span>}
			</div>
			<h2 className="break-words text-lg font-extrabold">
				{transaction.description}
			</h2>
			<p className="break-words text-[48px] font-black leading-tight">
				<mark className="rounded-xl bg-phrase-amount">
					{formatAmount(transaction.amount)}
				</mark>{" "}
				<span className="text-[20px] text-muted">{vi.common.currency}</span>
			</p>
			<div className="flex flex-wrap gap-2 text-[13px] font-bold">
				<span className="rounded-[14px] bg-phrase-payer px-3 py-[6px]">
					{transaction.type === "income"
						? `${vi.expenseForm.typeIncome}: ${payerNames}`
						: transaction.type === "transfer"
							? `${name(transaction.payers[0]?.memberId ?? "")} → ${name(transaction.shares[0]?.memberId ?? "")}`
							: t(vi.compose.payer, { name: payerNames })}
				</span>
				{transaction.type !== "transfer" && transaction.shares.length > 0 && (
					<span className="rounded-[14px] bg-phrase-split px-3 py-[6px]">
						{transaction.split.method === "exact"
							? t(vi.compose.exact, {
									parts: transaction.split.entries
										.map(
											(e) =>
												`${name(e.memberId)} ${formatCompactAmount(e.amount)}`,
										)
										.join(" · "),
								})
							: transaction.split.method === "items"
								? vi.split.methodItems
								: transaction.split.method === "shares"
									? vi.split.methodShares
									: transaction.split.method === "percent"
										? vi.split.methodPercent
										: t(equal ? vi.compose.equal : vi.compose.equalUneven, {
												count: String(transaction.shares.length),
												amount: formatAmount(
													transaction.shares[0]?.amount ?? 0,
												),
											})}
					</span>
				)}
			</div>
			{categoryLabel && (
				<div>
					<span className="inline-flex min-h-9 items-center gap-2 rounded-[18px] bg-sunken px-3 text-[13px] font-bold text-ink">
						{customCategory && (
							<span
								aria-hidden="true"
								className={`h-3 w-3 shrink-0 rounded-full ${CATEGORY_COLORS[customCategory.color].bg}`}
							/>
						)}
						<span>{categoryLabel}</span>
					</span>
				</div>
			)}
			{transaction.split.method === "items" && (
				<ul className="grid gap-1.5 rounded-[22px] bg-bg p-3 text-xs">
					{(() => {
						const counts = new Map<string, number>();
						return transaction.split.items.map((item) => {
							const base = `${item.name}:${item.amount}:${item.memberIds.join(",")}`;
							const seen = (counts.get(base) ?? 0) + 1;
							counts.set(base, seen);
							return (
								<li
									key={`${base}#${seen}`}
									className="flex items-center justify-between gap-2"
								>
									<span className="min-w-0 break-words font-semibold">
										{item.name}
										{item.memberIds.length > 0 && (
											<span className="ml-1.5 font-normal text-muted">
												({item.memberIds.map(name).join(", ")})
											</span>
										)}
									</span>
									<span className="shrink-0 font-bold">
										{formatAmount(item.amount)} {vi.common.currency}
									</span>
								</li>
							);
						});
					})()}
				</ul>
			)}
			{transaction.type !== "transfer" && transaction.shares.length > 0 && (
				<ShareShapes
					shares={transaction.shares.flatMap((s) => {
						const member = members.find((m) => m.id === s.memberId);
						return member ? [{ member, amount: s.amount }] : [];
					})}
				/>
			)}
			{transaction.deletedAt === null && transaction.attachments.length > 0 && (
				<PhotoRow
					groupId={groupId}
					attachments={transaction.attachments}
					readOnly
				/>
			)}
		</section>
	);
}
