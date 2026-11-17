"use client";
import {
	type MemberDto,
	type PaymentMethodInput,
	ReplacePaymentMethodsRequest,
} from "@songphang/contract";
import { useRef, useState } from "react";
import { usePaymentMethods } from "../../lib/members";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
export function usePaymentFields(groupId: string, member: MemberDto) {
	const bank = member.paymentMethods.find((method) => method.kind === "bank");
	const [bankBin, setBankBin] = useState(bank?.bankBin ?? "");
	const [accountNumber, setAccountNumber] = useState(bank?.accountNumber ?? "");
	const [accountName, setAccountName] = useState(bank?.accountName ?? "");
	const [momo, setMomo] = useState(
		member.paymentMethods.find((method) => method.kind === "momo")?.phone ?? "",
	);
	const [zalopay, setZalopay] = useState(
		member.paymentMethods.find((method) => method.kind === "zalopay")?.phone ??
			"",
	);
	const [saved, setSaved] = useState(false);
	const [invalid, setInvalid] = useState(false);
	const submitting = useRef(false);
	const mutation = usePaymentMethods(groupId);
	useSessionGuard(mutation.error);
	const methods: PaymentMethodInput[] = [];
	if (accountNumber)
		methods.push({ kind: "bank", bankBin, accountNumber, accountName });
	if (momo) methods.push({ kind: "momo", phone: momo });
	if (zalopay) methods.push({ kind: "zalopay", phone: zalopay });
	const parsed = ReplacePaymentMethodsRequest.safeParse({ methods });
	const error =
		invalid && !parsed.success
			? accountNumber && !/^[A-Za-z0-9]{4,19}$/.test(accountNumber)
				? vi.payment.invalidAccount
				: parsed.error.issues.some((issue) => issue.path.at(-1) === "phone")
					? vi.payment.invalidPhone
					: vi.common.saveError
			: mutation.isError
				? mutation.error.status === 403
					? vi.common.forbidden
					: vi.common.saveError
				: null;
	const save = () => {
		setSaved(false);
		if (!parsed.success) {
			setInvalid(true);
			return;
		}
		if (submitting.current) return;
		submitting.current = true;
		mutation.mutate(
			{ memberId: member.id, methods: parsed.data.methods },
			{
				onSuccess: () => {
					setSaved(true);
					setInvalid(false);
				},
				onSettled: () => {
					submitting.current = false;
				},
			},
		);
	};
	return {
		bankBin,
		setBankBin,
		accountNumber,
		setAccountNumber,
		accountName,
		setAccountName,
		momo,
		setMomo,
		zalopay,
		setZalopay,
		saved,
		error,
		save,
		isPending: mutation.isPending,
	};
}
