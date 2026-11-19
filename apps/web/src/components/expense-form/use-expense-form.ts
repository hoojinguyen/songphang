"use client";
import type {
	AttachmentDto,
	MemberDto,
	SplitTransactionRequest,
	TransactionDto,
} from "@songphang/contract";
import { CreateTransactionRequest, ParseDraft } from "@songphang/contract";
import { readSentence } from "@songphang/core";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { z } from "zod";
import { useDraft } from "../../lib/draft-context";
import { useGroup } from "../../lib/groups";
import { parseAmountInput } from "../../lib/money";
import {
	transactionRequestOf,
	useUpdateTransaction,
} from "../../lib/transaction-changes";
import { useCreateTransaction, usePreviewShares } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { useSnackbar } from "../ui/Snackbar";
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
	attachmentId?: string | null;
	text?: string | null;
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
	const draft = transaction ?? memory.draft?.draft ?? prefillDraft;
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
	const [amountText, setAmountText] = useState(
		draft?.amount ? String(draft.amount) : "",
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
		localDateTime(baseOccurredAt),
	);
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
		if (
			splitState.method === "items" &&
			splitState.itemsComputedAmount !== undefined &&
			splitState.itemsComputedAmount > 0 &&
			String(splitState.itemsComputedAmount) !== amountText
		) {
			setAmountText(String(splitState.itemsComputedAmount));
		}
	}, [splitState.method, splitState.itemsComputedAmount, amountText]);
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
	const payers = payerIds.map((memberId) => ({
		memberId,
		amount:
			payerIds.length === 1
				? amount
				: parseAmountInput(payerAmounts[memberId] ?? ""),
	}));
	const paid = payers.reduce((sum, payer) => sum + (payer.amount ?? 0), 0);
	const attachmentIds = attachments.map((attachment) => attachment.id);
	const optionalAttachments =
		transaction || attachmentIds.length > 0 ? { attachmentIds } : {};
	const parsed = CreateTransactionRequest.safeParse(
		type === "transfer"
			? {
					type,
					amount,
					occurredAt: timestamp,
					fromMemberId: transferFrom,
					toMemberId: transferTo,
					...(description.trim() ? { description: description.trim() } : {}),
					...optionalAttachments,
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
					...optionalAttachments,
				},
	);
	const request =
		parsed.success && (type === "transfer" || paid === amount)
			? parsed.data
			: null;
	if (initialRequestSnapshot.current === undefined && request && !transaction) {
		initialRequestSnapshot.current = JSON.stringify(request);
	}
	const preview = usePreviewShares(
		groupId,
		request?.type === "transfer" ? null : request,
		transaction?.id,
	);
	useSessionGuard(preview.error);
	const setType = (next: FormTransactionType) => {
		setTransactionType(next);
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
