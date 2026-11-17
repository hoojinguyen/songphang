"use client";
import {
	type AttachmentDto,
	CreateTransactionRequest,
	type MemberDto,
	type SplitTransactionRequest,
	type TransactionDto,
} from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { useDraft } from "../../lib/draft-context";
import { parseAmountInput } from "../../lib/money";
import {
	transactionRequestOf,
	useUpdateTransaction,
} from "../../lib/transaction-changes";
import { useCreateTransaction, usePreviewShares } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import type { FormTransactionType } from "./TypeSwitch";
import { useSplitState } from "./use-split-state";

export function localDateTime(value?: string) {
	const now = value ? new Date(value) : new Date();
	return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}T${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
}
export type FormPrefill = {
	type?: FormTransactionType;
	from?: string | null;
	to?: string | null;
};

export function useExpenseForm(
	groupId: string,
	members: MemberDto[],
	myMemberId: string | null,
	transaction?: TransactionDto,
	prefill?: FormPrefill,
) {
	const memory = useDraft();
	const draft = transaction ?? memory.draft?.draft;
	const active = members.filter(
		(member) => member.kind === "person" && (transaction || member.active),
	);
	const fund = members.find((member) => member.kind === "fund") ?? null;
	const payerOptions =
		fund && (transaction || fund.active) ? [...active, fund] : active;
	const transferMembers = members.filter(
		(member) => transaction || member.active,
	);
	const initial = active.some((member) => member.id === myMemberId)
		? myMemberId
		: null;
	const [type, setTransactionType] = useState<FormTransactionType>(
		transaction?.type ?? prefill?.type ?? "expense",
	);
	const [amountText, setAmountText] = useState(
		draft?.amount ? String(draft.amount) : "",
	);
	const [description, setDescription] = useState(draft?.description ?? "");
	const [category, setBuiltInCategory] = useState<
		SplitTransactionRequest["category"]
	>(transaction?.category ?? null);
	const [categoryId, setCustomCategoryId] = useState<string | null>(
		transaction?.categoryId ?? null,
	);
	const setCategory = (next: SplitTransactionRequest["category"]) => {
		setBuiltInCategory(next);
		if (next !== null) setCustomCategoryId(null);
	};
	const setCategoryId = (nextId: string | null) => {
		setCustomCategoryId(nextId);
		if (nextId !== null) setBuiltInCategory(null);
	};
	const [payerIds, setPayerIds] = useState<string[]>(
		draft ? draft.payers.map((p) => p.memberId) : initial ? [initial] : [],
	);
	const [payerAmounts, setPayerAmounts] = useState<Record<string, string>>(
		Object.fromEntries(
			transaction?.payers.map((p) => [p.memberId, String(p.amount)]) ?? [],
		),
	);

	const [transferFrom, setTransferFrom] = useState(
		transaction?.payers[0]?.memberId ??
			prefill?.from ??
			(initial && initial !== prefill?.to ? initial : null),
	);
	const [transferTo, setTransferTo] = useState<string | null>(
		transaction?.shares[0]?.memberId ?? prefill?.to ?? null,
	);
	const [occurredAt, setOccurredAt] = useState(() =>
		localDateTime(transaction?.occurredAt),
	);
	const [attachments, setAttachments] = useState<AttachmentDto[]>(
		transaction?.attachments ?? [],
	);
	const [key] = useState(() => crypto.randomUUID());
	const submitting = useRef(false);
	const create = useCreateTransaction(groupId);
	const update = useUpdateTransaction(
		groupId,
		transaction?.id ?? "",
		transaction?.version ?? 1,
	);
	const mutation = transaction ? update : create;
	const router = useRouter();
	useSessionGuard(mutation.error);
	const amount = parseAmountInput(amountText);
	const splitState = useSplitState(active, amount ?? 0, draft?.split);
	const date = new Date(occurredAt);
	const timestamp =
		transaction && occurredAt === localDateTime(transaction.occurredAt)
			? transaction.occurredAt
			: Number.isNaN(date.getTime())
				? ""
				: date.toISOString();
	const title = transaction
		? type === "expense"
			? vi.expenseForm.titleEdit
			: type === "income"
				? vi.expenseForm.titleEditIncome
				: vi.expenseForm.titleEditTransfer
		: type === "expense"
			? vi.expenseForm.title
			: type === "income"
				? vi.expenseForm.titleIncome
				: vi.expenseForm.titleTransfer;
	const payers = payerIds.map((memberId) => ({
		memberId,
		amount:
			payerIds.length === 1
				? amount
				: parseAmountInput(payerAmounts[memberId] ?? ""),
	}));
	const paid = payers.reduce((sum, payer) => sum + (payer.amount ?? 0), 0);
	const attachmentIds = attachments.map((attachment) => attachment.id);
	const parsed = CreateTransactionRequest.safeParse(
		type === "transfer"
			? {
					type,
					amount,
					occurredAt: timestamp,
					fromMemberId: transferFrom,
					toMemberId: transferTo,
					...(description.trim() ? { description: description.trim() } : {}),
					attachmentIds,
				}
			: {
					type,
					description: description.trim() || title,
					amount,
					occurredAt: timestamp,
					category,
					categoryId,
					payers,
					split: splitState.split,
					attachmentIds,
				},
	);
	const request =
		parsed.success && (type === "transfer" || paid === amount)
			? parsed.data
			: null;
	const preview = usePreviewShares(
		groupId,
		request?.type === "transfer" ? null : request,
		transaction?.id,
	);
	useSessionGuard(preview.error);
	const setType = (next: FormTransactionType) => {
		setTransactionType(next);
		if (next === "income")
			setPayerIds(initial ? [initial] : payerIds.slice(0, 1));
	};
	const togglePayer = (id: string) =>
		setPayerIds(
			type === "income"
				? [id]
				: payerIds.includes(id)
					? payerIds.filter((payer) => payer !== id)
					: [...payerIds, id],
		);
	const submit = () => {
		if (
			!request ||
			(type !== "transfer" && !description.trim()) ||
			submitting.current
		)
			return;
		submitting.current = true;
		mutation.mutate(
			{ request, key },
			{
				onSuccess: () => {
					memory.clear();
					router.replace(`/g/${groupId}`);
				},
				onSettled: () => {
					submitting.current = false;
				},
			},
		);
	};
	return {
		changed:
			!transaction ||
			JSON.stringify(request) !==
				JSON.stringify(
					CreateTransactionRequest.parse(transactionRequestOf(transaction)),
				),
		active,
		fund,
		payerOptions,
		transferMembers,
		groupId,
		type,
		setType,
		title,
		amount: amount ?? 0,
		amountText,
		setAmountText,
		description,
		setDescription,
		category,
		setCategory,
		categoryId,
		setCategoryId,
		payerIds,
		togglePayer,
		payerAmounts,
		setPayerAmount: (id: string, value: string) =>
			setPayerAmounts((current) => ({ ...current, [id]: value })),
		sharers: splitState.ids,
		setSharers: (ids: string[]) => {
			for (const id of active.map((m) => m.id))
				if (ids.includes(id) !== splitState.ids.includes(id))
					splitState.toggle(id);
		},
		splitState,
		transferFrom,
		setTransferFrom: (id: string) => {
			setTransferFrom(id);
			if (id === transferTo) setTransferTo(null);
		},
		transferTo,
		setTransferTo,
		occurredAt,
		setOccurredAt,
		attachments,
		addAttachment: (attachment: AttachmentDto) =>
			setAttachments((current) =>
				current.some((item) => item.id === attachment.id) || current.length >= 3
					? current
					: [...current, attachment],
			),
		removeAttachment: (id: string) =>
			setAttachments((current) => current.filter((item) => item.id !== id)),
		preview,
		mutation,
		request,
		submit,
	};
}
