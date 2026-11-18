"use client";
import { type MemberDto, TransactionDto } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { z } from "zod";
import { useBalances } from "../../lib/balances";
import { useDraft } from "../../lib/draft-context";
import { formatAmount, formatMoney, parseAmountInput } from "../../lib/money";
import {
	useDeleteTransaction,
	useRestoreTransaction,
} from "../../lib/transaction-changes";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ScreenHeader } from "../ui/ScreenHeader";
import { useSnackbar } from "../ui/Snackbar";
import { AmountField } from "./AmountField";
import { ConflictNotice } from "./ConflictNotice";
import { ParticipantFields } from "./ParticipantFields";
import { PhotoRow } from "./PhotoRow";
import { SplitEditor } from "./SplitEditor";
import { SplitStatus } from "./SplitStatus";
import { TransferFields } from "./TransferFields";
import { TypeSwitch } from "./TypeSwitch";
import { UnparsedBanner } from "./UnparsedBanner";
import { type FormPrefill, useExpenseForm } from "./use-expense-form";
export function ExpenseForm({
	groupId,
	members,
	transaction,
	current,
	onReload,
	myMemberId,
	prefill,
}: {
	groupId: string;
	members: MemberDto[];
	myMemberId: string | null;
	transaction?: TransactionDto;
	current?: TransactionDto;
	onReload?: (t: TransactionDto) => void;
	prefill?: FormPrefill;
}) {
	const memory = useDraft();
	const router = useRouter();
	const snackbar = useSnackbar();
	const balances = useBalances(groupId);
	const deletion = useDeleteTransaction(groupId);
	const restore = useRestoreTransaction(groupId);
	const [photoUploading, setPhotoUploading] = useState(false);
	const [splitOpen, setSplitOpen] = useState(
		(!transaction &&
			memory.draft?.issues.some((i) => i.code === "SUM_MISMATCH")) ??
			false,
	);
	const form = useExpenseForm(
		groupId,
		members,
		myMemberId,
		transaction,
		prefill,
	);
	const {
		active,
		fund,
		transferMembers,
		amountText,
		setAmountText,
		description,
		setDescription,
		type,
		setType,
		title,
		amount,
		payerIds,
		payerAmounts,
		transferFrom,
		setTransferFrom,
		transferTo,
		setTransferTo,
		splitState,
		occurredAt,
		setOccurredAt,
		attachments,
		addAttachment,
		removeAttachment,
		preview,
		mutation,
		request,
		submit,
	} = form;
	const conflictPayload = TransactionDto.safeParse(
		mutation.error?.details?.current,
	);
	const conflict =
		current ?? (conflictPayload.success ? conflictPayload.data : undefined);
	const deleteItem = () => {
		if (!transaction || deletion.isPending) return;
		deletion.mutate(transaction.id, {
			onSuccess: () => {
				router.replace(`/g/${groupId}`);
				snackbar({
					text: vi.expenseForm.deleted,
					action: {
						label: vi.expenseForm.undo,
						run: () => {
							void restore
								.mutateAsync(transaction.id)
								.then(() => snackbar({ text: vi.expenseForm.restored }))
								.catch(() => snackbar({ text: vi.common.saveError }));
						},
					},
				});
			},
		});
	};
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
				banner={
					!transaction ? <UnparsedBanner activeCount={active.length} /> : null
				}
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
				shares={
					request === null || !preview.current
						? []
						: (preview.data?.shares ?? [])
				}
				allowItems={type === "expense"}
				onDone={() => setSplitOpen(false)}
			/>
		);

	return (
		<div className="flex flex-1 flex-col gap-3">
			<UnparsedBanner activeCount={active.length} />
			<ScreenHeader
				title={title}
				{...(form.queueIndexLabel ? { subtitle: form.queueIndexLabel } : {})}
				backHref={
					transaction
						? `/g/${groupId}/tx/${transaction.id}/view`
						: memory.draft
							? `/g/${groupId}/tx/new`
							: `/g/${groupId}`
				}
				backLabel={vi.common.cancel}
				backIcon="close"
				trailing={
					transaction ? undefined : (
						<TypeSwitch value={type} onChange={setType} />
					)
				}
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
					members={transferMembers}
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
			<PhotoRow
				groupId={groupId}
				attachments={attachments}
				onAdd={addAttachment}
				onRemove={removeAttachment}
				onUploadingChange={setPhotoUploading}
			/>
			{mutation.isError && (
				<p role="alert">
					{mutation.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
			{preview.isError && <p role="alert">{vi.common.loadError}</p>}
			{type === "expense" &&
				preview.current &&
				preview.data?.warnings.includes("FUND_OVERDRAWN") &&
				fund &&
				balances.data?.fund &&
				(() => {
					const fundPaid = payerIds.includes(fund.id)
						? payerIds.length === 1
							? amount
							: (parseAmountInput(payerAmounts[fund.id] ?? "") ?? 0)
						: 0;
					const oldFundPaid =
						transaction?.payers.find((p) => p.memberId === fund.id)?.amount ??
						0;
					const beforeCash =
						balances.data.fund.cash +
						(transaction?.type === "expense"
							? oldFundPaid
							: transaction?.type === "income"
								? -oldFundPaid
								: 0);
					const overdraft = fundPaid - beforeCash;
					return overdraft > 0 ? (
						<p
							role="status"
							className="rounded-[20px] bg-phrase-amount px-4 py-3 text-sm font-bold text-ink"
						>
							{t(vi.fund.overdrawnWarning, {
								amount: formatMoney(overdraft),
							})}
						</p>
					) : null;
				})()}
			{type !== "transfer" &&
				preview.current &&
				preview.data?.warnings.includes("BUDGET_OVER") && (
					<p
						role="status"
						className="rounded-[20px] bg-coral px-4 py-3 text-sm font-bold text-ink"
					>
						{vi.budget.overWarning}
					</p>
				)}
			{type !== "transfer" && <SplitStatus {...status} />}
			{conflict && (
				<ConflictNotice
					current={conflict}
					onReload={() => onReload?.(conflict)}
				/>
			)}
			{deletion.isError && <p role="alert">{vi.common.saveError}</p>}
			<Button
				variant="accent"
				size="lg"
				onClick={() => {
					if (!photoUploading) submit();
				}}
				disabled={
					photoUploading ||
					!!conflict ||
					!form.changed ||
					request === null ||
					(type !== "transfer" && !description.trim()) ||
					mutation.isPending
				}
				className="mt-auto w-full"
			>
				{transaction
					? vi.expenseForm.saveChanges
					: form.hasMoreQueued
						? vi.compose.saveAndNext
						: type === "transfer"
							? vi.expenseForm.saveTransfer
							: type === "income"
								? vi.expenseForm.saveIncome
								: vi.expenseForm.save}
			</Button>
			{form.isMultiQueued && (
				<Button
					variant="surface"
					onClick={form.skipQueued}
					disabled={mutation.isPending}
					className="w-full"
				>
					{vi.compose.skipDraft}
				</Button>
			)}
			{transaction && (
				<Button
					variant="surface"
					onClick={deleteItem}
					disabled={deletion.isPending}
					className="w-full bg-debt-soft"
				>
					{vi.expenseForm.delete}
				</Button>
			)}
		</div>
	);
}
