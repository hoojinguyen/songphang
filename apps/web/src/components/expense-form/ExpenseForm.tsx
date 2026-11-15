"use client";
import type { MemberDto } from "@songphang/contract";
import { useState } from "react";
import { z } from "zod";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ScreenHeader } from "../ui/ScreenHeader";
import { AmountField } from "./AmountField";
import { ParticipantFields } from "./ParticipantFields";
import { SplitEditor } from "./SplitEditor";
import { SplitStatus } from "./SplitStatus";
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
	const [splitOpen, setSplitOpen] = useState(false);
	const form = useExpenseForm(groupId, members, myMemberId);
	const {
		active,
		amountText,
		setAmountText,
		description,
		setDescription,
		type,
		setType,
		title,
		amount,
		payerIds,
		transferFrom,
		setTransferFrom,
		transferTo,
		setTransferTo,
		splitState,
		occurredAt,
		setOccurredAt,
		preview,
		mutation,
		request,
		submit,
	} = form;
	const serverMismatch =
		mutation.error?.code === "SPLIT_TOTAL_MISMATCH"
			? z
					.object({ expected: z.number().int(), actual: z.number().int() })
					.safeParse(mutation.error.details)
			: null;
	const status = serverMismatch?.success
		? {
				matched: false,
				text: t(
					serverMismatch.data.actual > serverMismatch.data.expected
						? vi.split.over
						: vi.split.short,
					{
						amount:
							formatAmount(
								Math.abs(
									serverMismatch.data.actual - serverMismatch.data.expected,
								),
							) +
							" " +
							vi.common.currency,
					},
				),
			}
		: splitState.status;
	if (splitOpen)
		return (
			<SplitEditor
				state={splitState}
				members={active}
				amount={amount}
				description={description || title}
				payerLine={t(vi.expenseForm.payerAmountLabel, {
					name: active
						.filter((member) => payerIds.includes(member.id))
						.map((member) => member.name)
						.join(", "),
				})}
				shares={request === null ? [] : (preview.data?.shares ?? [])}
				onDone={() => setSplitOpen(false)}
			/>
		);

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
				<ParticipantFields
					form={form}
					myMemberId={myMemberId}
					onEdit={() => setSplitOpen(true)}
				/>
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
			{type !== "transfer" && <SplitStatus {...status} />}
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
