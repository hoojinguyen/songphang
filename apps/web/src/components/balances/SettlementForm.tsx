"use client";
import type { MemberDto } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { formatAmount, formatMoney, parseAmountInput } from "../../lib/money";
import { useCreateTransaction } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { ScreenHeader } from "../ui/ScreenHeader";
import { VerifyEmailBanner } from "../ui/VerifyEmailBanner";

function dateValue(daysAgo: number) {
	const date = new Date();
	date.setDate(date.getDate() - daysAgo);
	return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
export function SettlementForm({
	groupId,
	from,
	to,
	initialAmount,
	myMemberId,
	debt,
	verified,
}: {
	groupId: string;
	from: MemberDto;
	to: MemberDto;
	initialAmount: number;
	myMemberId: string | null;
	debt: number;
	verified: boolean;
}) {
	const [amountText, setAmountText] = useState(() =>
		formatAmount(initialAmount),
	);
	const [day, setDay] = useState(() => dateValue(0));
	const [otherDay, setOtherDay] = useState(false);
	const [key] = useState(() => crypto.randomUUID());
	const sending = useRef(false);
	const mutation = useCreateTransaction(groupId);
	const router = useRouter();
	useSessionGuard(mutation.error);
	const amount = parseAmountInput(amountText);
	const date = new Date(`${day}T12:00:00`);
	const validDate = !Number.isNaN(date.getTime());
	const title =
		to.id === myMemberId
			? vi.settle.titleReceived
			: from.id === myMemberId
				? vi.settle.titlePaid
				: vi.settle.title;
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-5 px-5 py-6">
			<ScreenHeader
				title={title}
				backHref={`/g/${groupId}/balances`}
				backLabel={vi.common.cancel}
				backIcon="close"
			/>
			<div className="flex items-center justify-around rounded-[40px] bg-surface p-5">
				{[from, to].map((member, index) => (
					<div key={member.id} className="flex items-center gap-3">
						<div className="grid justify-items-center gap-3">
							<MemberShape {...member} size={104} />
							<span className="text-sm font-extrabold">
								{member.id === myMemberId ? vi.common.you : member.name}
							</span>
						</div>
						{index === 0 && <Icon name="arrow-right" size={24} />}
					</div>
				))}
			</div>
			<label className="grid gap-2 text-sm font-bold">
				{t(vi.settle.amountLabel, { name: from.name })}
				<input
					aria-label={t(vi.settle.amountLabel, { name: from.name })}
					inputMode="numeric"
					value={amountText}
					onChange={(event) => {
						const value = parseAmountInput(event.target.value);
						if (value !== null || !event.target.value)
							setAmountText(value === null ? "" : formatAmount(value));
					}}
					className="h-24 min-w-0 w-full rounded-[32px] border-[3px] border-ink bg-surface px-4 text-center text-[46px] font-black"
				/>
			</label>
			<p className="text-[13px] text-muted">
				{t(vi.settle.partialHint, { name: from.name })}
			</p>
			<fieldset
				aria-label={vi.expenseForm.occurredAtLabel}
				className="flex gap-2"
			>
				{[
					{ label: vi.settle.today, days: 0 },
					{ label: vi.settle.yesterday, days: 1 },
					{ label: vi.settle.otherDay, days: null },
				].map((option) => (
					<button
						key={option.label}
						type="button"
						aria-pressed={
							option.days === null
								? otherDay
								: !otherDay && day === dateValue(option.days)
						}
						onClick={() => {
							setOtherDay(option.days === null);
							if (option.days !== null) setDay(dateValue(option.days));
						}}
						className={`min-h-11 flex-1 rounded-pill px-2 text-sm font-bold ${(option.days === null ? otherDay : !otherDay && day === dateValue(option.days)) ? "bg-ink text-surface" : "bg-surface"}`}
					>
						{option.label}
					</button>
				))}
			</fieldset>
			{otherDay && (
				<input
					type="date"
					aria-label={vi.settle.otherDay}
					value={day}
					onChange={(event) => setDay(event.target.value)}
					className="min-h-14 min-w-0 rounded-pill bg-surface px-4"
				/>
			)}
			{amount !== null && amount === debt && (
				<p
					role="status"
					className="rounded-[22px] bg-phrase-split p-4 text-sm font-bold"
				>
					{t(vi.settle.clears, { name: from.name })}
				</p>
			)}
			{mutation.isError && (
				<p role="alert">
					{mutation.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
			{verified ? (
				<Button
					variant="accent"
					size="lg"
					className="min-h-[68px]"
					disabled={!amount || !validDate || mutation.isPending}
					onClick={() => {
						if (!amount || !validDate || sending.current) return;
						sending.current = true;
						mutation.mutate(
							{
								key,
								request: {
									type: "transfer",
									fromMemberId: from.id,
									toMemberId: to.id,
									amount,
									occurredAt: date.toISOString(),
								},
							},
							{
								onSuccess: () => router.replace(`/g/${groupId}/balances`),
								onSettled: () => {
									sending.current = false;
								},
							},
						);
					}}
				>
					{t(vi.settle.submit, { amount: formatMoney(amount ?? 0) })}
				</Button>
			) : (
				<VerifyEmailBanner />
			)}
		</main>
	);
}
