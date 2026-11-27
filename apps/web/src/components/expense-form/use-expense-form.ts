"use client";
import type {
	AttachmentDto,
	MemberDto,
	RecurringExpenseDto,
	RecurringFrequency,
	RecurringMode,
	SplitTransactionRequest,
	TransactionDto,
} from "@songphang/contract";
import {
	CreateTransactionRequest,
	ParseDraft,
	PreviewExtrasRequest,
	type SplitInput,
} from "@songphang/contract";
import { readSentence } from "@songphang/core";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { z } from "zod";
import { useDraft } from "../../lib/draft-context";
import { useGroup } from "../../lib/groups";
import { formatAmount, parseAmountInput } from "../../lib/money";
import {
	transactionRequestOf,
	useUpdateTransaction,
} from "../../lib/transaction-changes";
import {
	useCreateTransaction,
	usePreviewExtras,
	usePreviewShares,
} from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { useSnackbar } from "../ui/Snackbar";
import type { FormTransactionType } from "./TypeSwitch";
import { toPreviewExtrasItems, useSplitState } from "./use-split-state";

export function localDateTime(value?: string) {
	const now = value ? new Date(value) : new Date();
	return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}T${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
}

type InitialFormDraft = {
	amount: number | null;
	description: string | null;
	category: SplitTransactionRequest["category"];
	categoryId: string | null;
	payers: ReadonlyArray<{ memberId: string; amount?: number | undefined }>;
	split: SplitInput | null;
};

function initialBaseAmountOf(
	draft: InitialFormDraft | undefined,
): number | null {
	if (!draft?.amount) return null;
	const draftSplit = draft.split;
	const draftExtras = draftSplit?.extras ?? [];
	if (draftSplit && draftSplit.method !== "items" && draftExtras.length > 0) {
		const netExtras = draftExtras.reduce(
			(sum, extra) =>
				sum + (extra.kind === "discount" ? -extra.amount : extra.amount),
			0,
		);
		return draft.amount - netExtras;
	}
	return draft.amount;
}
export type FormPrefill = {
	type?: FormTransactionType;
	from?: string | null;
	to?: string | null;
	attachmentId?: string | null;
	text?: string | null;
	recurringTemplate?: RecurringExpenseDto;
};

export function useExpenseForm(
	groupId: string,
	members: MemberDto[],
	myMemberId: string | null,
	transaction?: TransactionDto,
	prefill?: FormPrefill,
) {
	const memory = useDraft();
	const parsedFromText =
		!transaction && !memory.draft?.draft && prefill?.text?.trim()
			? readSentence({
					text: prefill.text.trim().normalize("NFC"),
					members: members.map((member) => ({
						id: member.id,
						name: member.name,
						kind: member.kind === "fund" ? "fund" : "person",
						active: member.active,
						position: member.position,
					})),
					writerMemberId: myMemberId,
				})
			: null;
	const prefillDraft: ParseDraft | undefined = parsedFromText
		? ParseDraft.parse({
				type: "expense",
				description:
					parsedFromText.draft.description ??
					prefill?.text?.trim().slice(0, 200) ??
					"",
				amount: parsedFromText.draft.amount,
				category: null,
				categoryId: null,
				payers:
					parsedFromText.draft.payerMemberId && parsedFromText.draft.amount
						? [
								{
									memberId: parsedFromText.draft.payerMemberId,
									amount: parsedFromText.draft.amount,
								},
							]
						: [],
				split: parsedFromText.draft.split,
			})
		: undefined;
	const recurringPrefill: InitialFormDraft | undefined =
		!transaction && prefill?.recurringTemplate
			? {
					description: prefill.recurringTemplate.description,
					amount: prefill.recurringTemplate.amount,
					category: prefill.recurringTemplate.category,
					categoryId: prefill.recurringTemplate.categoryId,
					payers: prefill.recurringTemplate.payersTemplate,
					split: prefill.recurringTemplate.splitTemplate,
				}
			: undefined;
	const draft: InitialFormDraft | undefined =
		transaction ?? recurringPrefill ?? memory.draft?.draft ?? prefillDraft;
	const activeQueue =
		!transaction &&
		memory.draft &&
		memory.queue &&
		memory.queue.sentence === memory.draft.sentence
			? memory.queue
			: null;
	const queuedItem = activeQueue?.items[activeQueue.index];
	const hasMoreQueued = Boolean(
		activeQueue && activeQueue.index + 1 < activeQueue.items.length,
	);
	const isMultiQueued = Boolean(activeQueue && activeQueue.items.length > 1);
	const queueIndexLabel =
		activeQueue && isMultiQueued
			? t(vi.compose.draftIndex, {
					index: String(activeQueue.index + 1),
					count: String(activeQueue.items.length),
				})
			: undefined;
	const baseOccurredAt = transaction?.occurredAt ?? queuedItem?.occurredAt;
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
	const initialBaseAmount = initialBaseAmountOf(draft);
	const [amountText, setAmountText] = useState(
		initialBaseAmount !== null && initialBaseAmount > 0
			? formatAmount(initialBaseAmount)
			: "",
	);
	const [description, setDescription] = useState(draft?.description ?? "");
	const [category, setBuiltInCategory] = useState<
		SplitTransactionRequest["category"]
	>(draft?.category ?? null);
	const [categoryId, setCustomCategoryId] = useState<string | null>(
		draft?.categoryId ?? null,
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
		draft && draft.payers.length > 0
			? draft.payers.map((p) => p.memberId)
			: initial
				? [initial]
				: [],
	);
	const [payerAmounts, setPayerAmounts] = useState<Record<string, string>>(
		Object.fromEntries(
			(draft?.payers ?? []).flatMap((p) =>
				p.amount !== undefined ? [[p.memberId, String(p.amount)]] : [],
			),
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
		localDateTime(baseOccurredAt),
	);
	const [recurringEnabled, setRecurringEnabled] = useState(false);
	const [recurringMode, setRecurringMode] = useState<RecurringMode>("fixed");
	const [recurringFrequency, setRecurringFrequency] =
		useState<RecurringFrequency>("monthly");
	const [attachments, setAttachments] = useState<AttachmentDto[]>(() => {
		if (transaction?.attachments && transaction.attachments.length > 0) {
			return transaction.attachments;
		}
		if (
			prefill?.attachmentId &&
			z.uuid().safeParse(prefill.attachmentId).success
		) {
			return [
				{
					id: prefill.attachmentId,
					contentType: "image/jpeg",
					byteSize: 1,
					transactionId: null,
					createdAt: new Date().toISOString(),
				},
			];
		}
		return [];
	});
	const [key] = useState(
		() => queuedItem?.idempotencyKey ?? crypto.randomUUID(),
	);
	const initialRequestSnapshot = useRef<string | undefined>(undefined);
	const submitting = useRef(false);
	const create = useCreateTransaction(groupId);
	const update = useUpdateTransaction(
		groupId,
		transaction?.id ?? "",
		transaction?.version ?? 1,
	);
	const mutation = transaction ? update : create;
	const group = useGroup(groupId);
	const snackbar = useSnackbar();
	const router = useRouter();
	useSessionGuard(mutation.error);
	const amount = parseAmountInput(amountText);
	const splitState = useSplitState(active, amount ?? 0, draft?.split, groupId);
	useEffect(() => {
		if (splitState.method !== "items") return;
		const syncedAmount =
			splitState.extras.length > 0
				? splitState.itemsBaseAmount
				: (splitState.itemsComputedAmount ?? 0);
		if (syncedAmount > 0 && syncedAmount !== amount) {
			setAmountText(formatAmount(syncedAmount));
		}
	}, [
		splitState.method,
		splitState.extras.length,
		splitState.itemsBaseAmount,
		splitState.itemsComputedAmount,
		amount,
	]);
	const date = new Date(occurredAt);
	const timestamp =
		baseOccurredAt && occurredAt === localDateTime(baseOccurredAt)
			? baseOccurredAt
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
	const hasManualExtras = type === "expense" && splitState.extras.length > 0;
	const previewExtrasItems = hasManualExtras
		? toPreviewExtrasItems(splitState.extras)
		: null;
	const extrasBaseAmount =
		splitState.method === "items" ? splitState.itemsBaseAmount : (amount ?? 0);
	const parsedExtrasPreview =
		hasManualExtras && previewExtrasItems !== null
			? PreviewExtrasRequest.safeParse({
					baseAmount: extrasBaseAmount,
					extras: previewExtrasItems,
					extrasAllocation: splitState.extrasAllocation,
					...(payerIds.length === 1 && payerIds[0]
						? { payerMemberId: payerIds[0] }
						: payerIds.length > 1 &&
								payerIds.every(
									(id) => (parseAmountInput(payerAmounts[id] ?? "") ?? 0) > 0,
								)
							? {
									payers: payerIds.map((id) => ({
										memberId: id,
										amount: parseAmountInput(payerAmounts[id] ?? "") ?? 0,
									})),
								}
							: {}),
					...(splitState.baseSplit ? { split: splitState.baseSplit } : {}),
					...(timestamp ? { occurredAt: timestamp } : {}),
					...(transaction?.id ? { transactionId: transaction.id } : {}),
				})
			: null;
	const extrasPreview = usePreviewExtras(
		groupId,
		parsedExtrasPreview?.success ? parsedExtrasPreview.data : null,
	);
	useSessionGuard(extrasPreview.error);

	const effectiveTotalAmount = hasManualExtras
		? extrasPreview.current &&
			extrasPreview.data &&
			extrasPreview.data.issues.length === 0 &&
			extrasPreview.data.computedAmount > 0
			? extrasPreview.data.computedAmount
			: null
		: splitState.method === "items"
			? splitState.itemsComputedAmount && splitState.itemsComputedAmount > 0
				? splitState.itemsComputedAmount
				: null
			: amount;

	const finalSplit: SplitInput | null = hasManualExtras
		? splitState.baseSplit &&
			extrasPreview.current &&
			extrasPreview.data &&
			extrasPreview.data.issues.length === 0
			? {
					...splitState.baseSplit,
					extras: extrasPreview.data.resolvedExtras,
					extrasAllocation: splitState.extrasAllocation,
				}
			: null
		: splitState.split;

	const payers = payerIds.map((memberId) => ({
		memberId,
		amount:
			payerIds.length === 1
				? effectiveTotalAmount
				: parseAmountInput(payerAmounts[memberId] ?? ""),
	}));
	const paid = payers.reduce((sum, payer) => sum + (payer.amount ?? 0), 0);
	const attachmentIds = attachments.map((attachment) => attachment.id);
	const optionalAttachments =
		transaction || attachmentIds.length > 0 ? { attachmentIds } : {};
	const canInlineRecurring =
		!transaction && !prefill?.recurringTemplate && type === "expense";
	const canVariableRecurring =
		payerIds.length === 1 &&
		(splitState.method === "equal" ||
			splitState.method === "shares" ||
			splitState.method === "percent");
	const effectiveRecurringMode: RecurringMode = canVariableRecurring
		? recurringMode
		: "fixed";
	const parsed = CreateTransactionRequest.safeParse(
		type === "transfer"
			? {
					type,
					amount,
					occurredAt: timestamp,
					fromMemberId: transferFrom,
					toMemberId: transferTo,
					...(description.trim() ? { description: description.trim() } : {}),
					...(transaction?.paymentChannel !== undefined
						? { paymentChannel: transaction.paymentChannel }
						: {}),
					...(transaction?.paymentNote !== undefined
						? { paymentNote: transaction.paymentNote }
						: {}),
					...optionalAttachments,
				}
			: {
					type,
					description: description.trim() || title,
					amount: effectiveTotalAmount,
					occurredAt: timestamp,
					category,
					categoryId,
					payers,
					split: finalSplit,
					...optionalAttachments,
					...(prefill?.recurringTemplate
						? { recurringExpenseId: prefill.recurringTemplate.id }
						: canInlineRecurring && recurringEnabled
							? {
									recurring: {
										mode: effectiveRecurringMode,
										frequency: recurringFrequency,
									},
								}
							: {}),
				},
	);
	const request =
		parsed.success &&
		(type === "transfer" ||
			(effectiveTotalAmount !== null && paid === effectiveTotalAmount))
			? parsed.data
			: null;
	if (initialRequestSnapshot.current === undefined && request && !transaction) {
		initialRequestSnapshot.current = JSON.stringify(request);
	}
	const sharesPreview = usePreviewShares(
		groupId,
		hasManualExtras || request?.type === "transfer" ? null : request,
		transaction?.id,
	);
	useSessionGuard(sharesPreview.error);
	const preview = hasManualExtras
		? {
				...extrasPreview,
				data: extrasPreview.data
					? {
							shares: extrasPreview.data.shares ?? [],
							warnings: extrasPreview.data.warnings,
						}
					: undefined,
			}
		: sharesPreview;
	const setType = (next: FormTransactionType) => {
		setTransactionType(next);
		if (next !== "expense") {
			splitState.clearExtras();
		}
		if (next === "income") {
			setPayerIds(initial ? [initial] : payerIds.slice(0, 1));
			if (splitState.method === "items") splitState.changeMode("equal");
		}
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
		const payload =
			!transaction &&
			queuedItem?.submittedRequest &&
			initialRequestSnapshot.current !== undefined &&
			JSON.stringify(request) === initialRequestSnapshot.current
				? queuedItem.submittedRequest
				: request;
		submitting.current = true;
		mutation.mutate(
			{ request: payload, key },
			{
				onSuccess: (data) => {
					if (data.transaction.approval.status === "pending") {
						snackbar({
							text: t(vi.approval.savedPending, {
								owner: group.data?.ownerName ?? "",
							}),
						});
					}
					if (activeQueue && activeQueue.index + 1 < activeQueue.items.length) {
						memory.setQueue({
							...activeQueue,
							index: activeQueue.index + 1,
						});
						memory.setDraft(null);
						router.replace(`/g/${groupId}/tx/new`);
						return;
					}
					memory.clear();
					router.replace(`/g/${groupId}`);
				},
				onSettled: () => {
					submitting.current = false;
				},
			},
		);
	};
	const skipQueued = () => {
		if (!activeQueue || submitting.current || mutation.isPending) return;
		if (activeQueue.index + 1 < activeQueue.items.length) {
			memory.setQueue({
				...activeQueue,
				index: activeQueue.index + 1,
			});
			memory.setDraft(null);
			router.replace(`/g/${groupId}/tx/new`);
			return;
		}
		memory.clear();
		router.replace(`/g/${groupId}`);
	};
	return {
		hasMoreQueued,
		isMultiQueued,
		queueIndexLabel,
		skipQueued,
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
		totalAmount: effectiveTotalAmount ?? amount ?? 0,
		hasManualExtras,
		extrasPreview,
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
		canInlineRecurring,
		canVariableRecurring,
		recurringEnabled,
		setRecurringEnabled,
		recurringMode: effectiveRecurringMode,
		setRecurringMode,
		recurringFrequency,
		setRecurringFrequency,
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
