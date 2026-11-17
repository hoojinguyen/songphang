"use client";
import type { MemberDto } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { TextField } from "../ui/TextField";
import { BankPicker } from "./BankPicker";
import { usePaymentFields } from "./use-payment-fields";
export function PaymentMethodsFields({
	groupId,
	member,
	canWrite,
}: {
	groupId: string;
	member: MemberDto;
	canWrite: boolean;
}) {
	const form = usePaymentFields(groupId, member);
	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-4">
			<h3 className="font-extrabold">{vi.payment.title}</h3>
			<p className="text-xs text-muted">
				{t(vi.payment.hint, { name: member.name })}
			</p>
			{canWrite ? (
				<>
					<BankPicker
						value={form.bankBin}
						onChange={form.setBankBin}
						disabled={form.isPending}
					/>
					<TextField
						label={vi.payment.accountNumber}
						value={form.accountNumber}
						maxLength={19}
						disabled={form.isPending}
						onChange={(event) => form.setAccountNumber(event.target.value)}
						{...(form.accountNumber &&
						!/^[A-Za-z0-9]+$/.test(form.accountNumber)
							? { error: vi.payment.invalidAccount }
							: {})}
					/>
					<TextField
						label={vi.payment.accountName}
						value={form.accountName}
						maxLength={50}
						disabled={form.isPending}
						onChange={(event) =>
							form.setAccountName(
								event.target.value
									.normalize("NFD")
									.replace(/\p{M}/gu, "")
									.replace(/[đĐ]/g, "D")
									.toLocaleUpperCase("vi"),
							)
						}
					/>
					<TextField
						label={vi.payment.momo}
						value={form.momo}
						maxLength={32}
						disabled={form.isPending}
						onChange={(event) => form.setMomo(event.target.value)}
						inputMode="tel"
					/>
					<TextField
						label={vi.payment.zalopay}
						value={form.zalopay}
						maxLength={32}
						disabled={form.isPending}
						onChange={(event) => form.setZalopay(event.target.value)}
						inputMode="tel"
					/>
					<Button
						variant="primary"
						disabled={form.isPending}
						onClick={form.save}
					>
						{vi.compose.save}
					</Button>
					{form.error && <p role="alert">{form.error}</p>}
					{form.saved && <p role="status">{vi.payment.saved}</p>}
				</>
			) : (
				<dl className="grid gap-2 break-all">
					{member.paymentMethods.map((method) => (
						<div key={method.kind}>
							{method.kind === "bank" ? (
								<>
									<dt>{vi.payment.bank}</dt>
									<dd>{method.bankShortName}</dd>
									<dt>{vi.payment.accountNumber}</dt>
									<dd>{method.accountNumber}</dd>
									<dt>{vi.payment.accountName}</dt>
									<dd>{method.accountName}</dd>
								</>
							) : (
								<>
									<dt>
										{method.kind === "momo"
											? vi.payment.momo
											: vi.payment.zalopay}
									</dt>
									<dd>{method.phone}</dd>
								</>
							)}
						</div>
					))}
				</dl>
			)}
		</section>
	);
}
