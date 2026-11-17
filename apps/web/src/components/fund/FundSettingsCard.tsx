"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useDeleteFund, useUpdateFund } from "../../lib/fund";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";

export function FundSettingsCard({
	groupId,
	fund,
	people,
}: {
	groupId: string;
	fund: NonNullable<BalancesResponse["fund"]>;
	people: MemberDto[];
}) {
	const router = useRouter();
	const [name, setName] = useState(fund.name);
	const [holderMemberId, setHolderMemberId] = useState(fund.holderMemberId);
	const update = useUpdateFund(groupId);
	const remove = useDeleteFund(groupId);
	useSessionGuard(update.error ?? remove.error);
	const busy = update.isPending || remove.isPending;

	const errorText =
		update.error?.code === "FUND_NOT_EMPTY"
			? vi.fund.closeNonEmpty
			: remove.error?.code === "MEMBER_HAS_TRANSACTIONS"
				? vi.fund.hasTransactions
				: update.isError || remove.isError
					? (update.error ?? remove.error)?.status === 403
						? vi.common.forbidden
						: vi.common.saveError
					: null;

	const dirty =
		name.trim() !== fund.name || holderMemberId !== fund.holderMemberId;
	return (
		<section className="grid gap-4 rounded-[30px] bg-surface p-5">
			<label className="grid gap-1 text-xs font-bold text-muted">
				{vi.fund.nameLabel}
				<input
					value={name}
					maxLength={50}
					onChange={(event) => setName(event.target.value)}
					className="h-12 min-w-0 rounded-[20px] bg-bg px-3 text-base font-bold text-ink"
				/>
			</label>
			<div className="grid gap-2">
				<span className="text-xs font-bold text-muted">
					{vi.fund.holderLabel}
				</span>
				<div className="flex flex-wrap gap-1.5">
					<button
						type="button"
						disabled={busy}
						aria-pressed={holderMemberId === null}
						onClick={() => setHolderMemberId(null)}
						className={`min-h-11 rounded-pill px-3 text-xs font-bold ${
							holderMemberId === null ? "bg-ink text-surface" : "bg-bg text-ink"
						}`}
					>
						{vi.fund.noHolder}
					</button>
					{people.map((person) => (
						<button
							key={person.id}
							type="button"
							disabled={busy}
							aria-pressed={holderMemberId === person.id}
							onClick={() => setHolderMemberId(person.id)}
							className={`min-h-11 rounded-pill px-3 text-xs font-bold ${
								holderMemberId === person.id
									? "bg-ink text-surface"
									: "bg-bg text-ink"
							}`}
						>
							{person.name}
						</button>
					))}
				</div>
			</div>
			<Button
				variant="primary"
				disabled={busy || !name.trim() || !dirty}
				onClick={() =>
					update.mutate({
						...(name.trim() !== fund.name ? { name: name.trim() } : {}),
						...(holderMemberId !== fund.holderMemberId
							? { holderMemberId }
							: {}),
					})
				}
			>
				{vi.fund.saveButton}
			</Button>
			<Button
				variant="surface"
				className="bg-bg"
				disabled={busy}
				onClick={() => update.mutate({ active: !fund.active })}
			>
				{fund.active ? vi.fund.closeButton : vi.fund.reopenButton}
			</Button>
			<Button
				variant="surface"
				className="bg-debt-soft"
				disabled={busy}
				onClick={() =>
					remove.mutate(undefined, {
						onSuccess: () => router.replace(`/g/${groupId}/members`),
					})
				}
			>
				{vi.fund.deleteButton}
			</Button>
			{errorText && (
				<p role="alert" className="text-sm font-bold text-ink">
					{errorText}
				</p>
			)}
		</section>
	);
}
