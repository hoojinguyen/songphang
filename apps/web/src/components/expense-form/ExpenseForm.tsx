"use client";
import type { MemberDto } from "@songphang/contract";
import { formatAmount } from "../../lib/money";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ScreenHeader } from "../ui/ScreenHeader";
import { AmountField } from "./AmountField";
import { CategoryPicker } from "./CategoryPicker";
import { MemberToggleGrid } from "./MemberToggleGrid";
import { PayerAmounts } from "./PayerAmounts";
import { TransferFields } from "./TransferFields";
import { TypeSwitch } from "./TypeSwitch";
import { useExpenseForm } from "./use-expense-form";
export function ExpenseForm({
	groupId,
	members,
	myMemberId,
}: {
	groupId: string;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const {
		active,
		amountText,
		setAmountText,
		description,
		setDescription,
		category,
		setCategory,
		type,
		setType,
		title,
		amount,
		payerIds,
		togglePayer,
		payerAmounts,
		setPayerAmount,
		transferFrom,
		setTransferFrom,
		transferTo,
		setTransferTo,
		sharers,
		setSharers,
		occurredAt,
		setOccurredAt,
		preview,
		mutation,
		request,
		submit,
	} = useExpenseForm(groupId, members, myMemberId);
	return (
		<div className="flex flex-1 flex-col gap-3">
			<ScreenHeader
				title={title}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.cancel}
				backIcon="close"
				trailing={<TypeSwitch value={type} onChange={setType} />}
			/>
			<AmountField value={amountText} onChange={setAmountText} />
			<input
				aria-label={vi.expenseForm.descriptionLabel}
				placeholder={
					type === "transfer"
						? vi.expenseForm.descriptionTransferPlaceholder
						: vi.expenseForm.descriptionPlaceholder
				}
				maxLength={200}
				value={description}
				onChange={(event) => setDescription(event.target.value)}
				className="h-14 shrink-0 rounded-[26px] bg-surface px-4 text-[17px] font-extrabold"
			/>

			{type === "transfer" ? (
				<TransferFields
					members={active}
					from={transferFrom}
					to={transferTo}
					onFrom={setTransferFrom}
					onTo={setTransferTo}
				/>
			) : (
				<>
					<CategoryPicker value={category} onChange={setCategory} />
					<section className="rounded-[30px] bg-surface p-3">
						<h2 className="mb-2 text-sm font-extrabold">
							{type === "income"
								? vi.expenseForm.receiverTitle
								: vi.expenseForm.payerTitle}
						</h2>
						<MemberToggleGrid
							members={active}
							selectedIds={payerIds}
							onToggle={togglePayer}
							captionFor={(member) =>
								member.id === myMemberId ? vi.common.you : member.name
							}
							label={
								type === "income"
									? vi.expenseForm.receiverTitle
									: vi.expenseForm.payerTitle
							}
						/>
					</section>
					{payerIds.length > 1 && (
						<PayerAmounts
							members={active.filter((member) => payerIds.includes(member.id))}
							values={payerAmounts}
							amount={amount}
							onChange={setPayerAmount}
						/>
					)}
					<section className="rounded-[30px] bg-surface p-3">
						<div className="mb-2 flex items-center justify-between">
							<h2 className="text-sm font-extrabold">
								{vi.expenseForm.sharersTitle}
							</h2>
							<span className="rounded-[22px] bg-phrase-split px-3 py-1 text-xs">
								{vi.expenseForm.equalSplit}
							</span>
						</div>
						<MemberToggleGrid
							members={active}
							selectedIds={sharers}
							onToggle={(id) =>
								setSharers(
									sharers.includes(id)
										? sharers.filter((memberId) => memberId !== id)
										: [...sharers, id],
								)
							}
							captionFor={(member) => {
								if (!sharers.includes(member.id)) return member.name;
								const share = preview.data?.shares.find(
									(share) => share.memberId === member.id,
								);
								return share
									? formatAmount(share.amount)
									: vi.common.pendingValue;
							}}
							label={vi.expenseForm.sharersTitle}
						/>
						{sharers.length === 0 && (
							<p role="alert" className="mt-2 text-xs text-muted">
								{vi.expenseForm.needSharer}
							</p>
						)}
					</section>
				</>
			)}
			<label className="grid gap-1 text-xs text-muted">
				{vi.expenseForm.occurredAtLabel}
				<input
					type="datetime-local"
					value={occurredAt}
					onChange={(event) => setOccurredAt(event.target.value)}
					className="h-16 min-w-0 w-full rounded-[32px] bg-surface px-4 text-base text-ink"
				/>
			</label>
			{mutation.isError && (
				<p role="alert">
					{mutation.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
			{preview.isError && <p role="alert">{vi.common.loadError}</p>}
			<Button
				variant="accent"
				size="lg"
				onClick={submit}
				disabled={
					request === null ||
					(type !== "transfer" && !description.trim()) ||
					mutation.isPending
				}
				className="mt-auto w-full"
			>
				{type === "transfer"
					? vi.expenseForm.saveTransfer
					: type === "income"
						? vi.expenseForm.saveIncome
						: vi.expenseForm.save}
			</Button>
		</div>
	);
}
