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
	const [amountText, setAmountText] = useState("");
	const [description, setDescription] = useState("");
	const [category, setCategory] =
		useState<SplitTransactionRequest["category"]>(null);
	const [payer, setPayer] = useState<string | null>(
		active.some((member) => member.id === myMemberId) ? myMemberId : null,
	);
	const [sharers, setSharers] = useState(active.map((member) => member.id));
	const [occurredAt, setOccurredAt] = useState(localDateTime);
	const [key] = useState(() => crypto.randomUUID());
	const submitting = useRef(false);
	const mutation = useCreateTransaction(groupId);
	const router = useRouter();
	useSessionGuard(mutation.error);
	const amount = parseAmountInput(amountText);
	const date = new Date(occurredAt);
	const parsed = CreateTransactionRequest.safeParse({
		type: "expense",
		description: description.trim() || vi.expenseForm.title,
		amount,
		occurredAt: Number.isNaN(date.getTime()) ? "" : date.toISOString(),
		category,
		payers: payer === null ? [] : [{ memberId: payer, amount }],
		split: { method: "equal", members: sharers },
	});
	const request = parsed.success ? parsed.data : null;
	const preview = usePreviewShares(groupId, request);
	useSessionGuard(preview.error);
	const submit = () => {
		if (request === null || !description.trim() || submitting.current) return;
		submitting.current = true;
		mutation.mutate(
			{ request: { ...request, description: description.trim() }, key },
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
		amountText,
		setAmountText,
		description,
		setDescription,
		category,
		setCategory,
		payer,
		setPayer,
		sharers,
		setSharers,
		occurredAt,
		setOccurredAt,
		preview,
		mutation,
		request,
		submit,
	};
}
