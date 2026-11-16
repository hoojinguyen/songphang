"use client";
import type { InvitePreviewResponse } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useJoin } from "../../lib/invites";
import { formatMoney } from "../../lib/money";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { OnlineButton } from "../ui/OnlineButton";
import { TextField } from "../ui/TextField";
import { VerifyEmailBanner } from "../ui/VerifyEmailBanner";
import { ClaimGrid, normalizeMemberName } from "./ClaimGrid";

function BalanceHint({ name, balance }: { name: string; balance: number }) {
	const template =
		balance < 0 ? vi.join.owes : balance > 0 ? vi.join.isOwed : vi.join.even;
	const [before, after] = template.split("{amount}");
	return (
		<p className="rounded-[26px] bg-surface p-4 text-[13px]">
			{t(before ?? "", { name })}
			{balance !== 0 && (
				<strong className="font-extrabold text-ink">
					{formatMoney(Math.abs(balance))}
				</strong>
			)}
			{after}
		</p>
	);
}
export function JoinForm({
	token,
	preview,
	accountName,
	verified,
	onRefresh,
}: {
	token: string;
	preview: InvitePreviewResponse;
	accountName: string;
	verified: boolean;
	onRefresh: () => void;
}) {
	const router = useRouter();
	const mutation = useJoin(token);
	const [key] = useState(() => crypto.randomUUID());
	const [selected, setSelected] = useState<string | null>(
		() =>
			preview.members.find(
				(m) =>
					!m.claimed &&
					normalizeMemberName(m.name) === normalizeMemberName(accountName),
			)?.id ?? null,
	);
	const [isNew, setIsNew] = useState(false);
	const [name, setName] = useState(accountName);
	const member = preview.members.find((m) => m.id === selected && !m.claimed);
	const chosenName = isNew ? name.trim() : (member?.name ?? "");
	useSessionGuard(mutation.error);
	return (
		<>
			<ClaimGrid
				members={preview.members}
				accountName={accountName}
				selected={isNew ? null : selected}
				onSelect={(id) => {
					setSelected(id);
					setIsNew(false);
				}}
			/>
			{isNew ? (
				<TextField
					label={vi.join.newMemberLabel}
					required
					maxLength={50}
					value={name}
					onChange={(event) => setName(event.target.value)}
				/>
			) : (
				<OnlineButton
					type="button"
					className="min-h-[60px] rounded-[30px] border-2 border-dashed border-muted px-4 font-bold"
					onClick={() => {
						setIsNew(true);
						setSelected(null);
					}}
				>
					{vi.join.newMember}
				</OnlineButton>
			)}
			{member && (
				<BalanceHint name={member.name} balance={member.balance ?? 0} />
			)}
			{mutation.isError && (
				<p role="alert">
					{mutation.error.code === "MEMBER_ALREADY_CLAIMED"
						? vi.join.claimedMeanwhile
						: vi.common.saveError}
				</p>
			)}
			{verified ? (
				<Button
					variant="accent"
					size="lg"
					className="min-h-[68px] rounded-[34px] text-lg font-black"
					disabled={!chosenName || mutation.isPending || (!isNew && !member)}
					onClick={() => {
						if (!chosenName || (!isNew && !member) || mutation.isPending)
							return;
						mutation.mutate(
							{
								request: isNew
									? { newMemberName: chosenName }
									: { memberId: member?.id ?? "" },
								key,
							},
							{
								onSuccess: (result) => router.replace(`/g/${result.groupId}`),
								onError: (error) => {
									if (error.code === "MEMBER_ALREADY_CLAIMED") {
										setSelected(null);
										onRefresh();
									}
								},
							},
						);
					}}
				>
					{t(vi.join.submit, { name: chosenName })}
				</Button>
			) : (
				<VerifyEmailBanner />
			)}
		</>
	);
}
