"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
	type SplitTransactionRequest,
} from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { parseAmountInput } from "../../lib/money";
import { useCreateTransaction, usePreviewShares } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import type { FormTransactionType } from "./TypeSwitch";

function localDateTime() {
	const now = new Date();
	return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}T${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
}
export function useExpenseForm(
	groupId: string,
	members: MemberDto[],
	myMemberId: string | null,
) {
	const active = members.filter((member) => member.active);
	const initial = active.some((member) => member.id === myMemberId)
		? myMemberId
		: null;
	const [type, setTransactionType] = useState<FormTransactionType>("expense");
	const [amountText, setAmountText] = useState("");
	const [description, setDescription] = useState("");
	const [category, setCategory] =
		useState<SplitTransactionRequest["category"]>(null);
	const [payerIds, setPayerIds] = useState<string[]>(initial ? [initial] : []);
	const [payerAmounts, setPayerAmounts] = useState<Record<string, string>>({});
	const [sharers, setSharers] = useState(active.map((member) => member.id));
	const [transferFrom, setTransferFrom] = useState(initial);
	const [transferTo, setTransferTo] = useState<string | null>(null);
	const [occurredAt, setOccurredAt] = useState(localDateTime);
	const [key] = useState(() => crypto.randomUUID());
	const submitting = useRef(false);
	const mutation = useCreateTransaction(groupId);
	const router = useRouter();
	useSessionGuard(mutation.error);
	const amount = parseAmountInput(amountText);
	const date = new Date(occurredAt);
	const timestamp = Number.isNaN(date.getTime()) ? "" : date.toISOString();
	const title =
		type === "expense"
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
	const parsed = CreateTransactionRequest.safeParse(
		type === "transfer"
			? {
					type,
					amount,
					occurredAt: timestamp,
					fromMemberId: transferFrom,
					toMemberId: transferTo,
					...(description.trim() ? { description: description.trim() } : {}),
				}
			: {
					type,
					description: description.trim() || title,
					amount,
					occurredAt: timestamp,
					category,
					payers,
					split: { method: "equal", members: sharers },
				},
	);
	const request =
		parsed.success && (type === "transfer" || paid === amount)
			? parsed.data
			: null;
	const preview = usePreviewShares(
		groupId,
		request?.type === "transfer" ? null : request,
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
				onSuccess: () => router.replace(`/g/${groupId}`),
				onSettled: () => {
					submitting.current = false;
				},
			},
		);
	};
	return {
		active,
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
		payerIds,
		togglePayer,
		payerAmounts,
		setPayerAmount: (id: string, value: string) =>
			setPayerAmounts((current) => ({ ...current, [id]: value })),
		sharers,
		setSharers,
		transferFrom,
		setTransferFrom: (id: string) => {
			setTransferFrom(id);
			if (id === transferTo) setTransferTo(null);
		},
		transferTo,
		setTransferTo,
		occurredAt,
		setOccurredAt,
		preview,
		mutation,
		request,
		submit,
	};
}
