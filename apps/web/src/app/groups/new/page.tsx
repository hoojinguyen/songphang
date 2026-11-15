"use client";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { NewGroupMembers } from "../../../components/groups/NewGroupMembers";
import { Button } from "../../../components/ui/Button";
import { LoadError } from "../../../components/ui/LoadError";
import { ScreenHeader } from "../../../components/ui/ScreenHeader";
import { VerifyEmailBanner } from "../../../components/ui/VerifyEmailBanner";
import { useCreateGroup } from "../../../lib/groups";
import { useMe } from "../../../lib/session";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { t, vi } from "../../../messages/vi";
export default function NewGroupPage() {
	const me = useMe();
	const create = useCreateGroup();
	const router = useRouter();
	const [name, setName] = useState("");
	const [names, setNames] = useState<Array<{ id: string; name: string }>>([]);
	const [key] = useState(() => crypto.randomUUID());
	const submitting = useRef(false);
	const nameInput = useRef<HTMLInputElement>(null);
	const userId = me.data?.id;
	useEffect(() => {
		if (userId) nameInput.current?.focus();
	}, [userId]);
	useSessionGuard(me.error ?? create.error);

	const submit = () => {
		if (!name.trim() || submitting.current || !me.data) return;
		submitting.current = true;
		create.mutate(
			{
				request: {
					name: name.trim(),
					memberNames: names.map((member) => member.name),
				},
				key,
			},
			{
				onSuccess: (group) => router.replace(`/g/${group.id}`),
				onSettled: () => {
					submitting.current = false;
				},
			},
		);
	};
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6">
			<ScreenHeader
				title={vi.newGroup.title}
				backHref="/"
				backLabel={vi.common.back}
			/>
			{me.isPending || me.error?.status === 401 ? (
				<div aria-busy="true" className="h-72 rounded-card bg-sunken" />
			) : me.isError ? (
				<LoadError
					onRetry={() => {
						void me.refetch();
					}}
					isRetrying={me.isFetching}
				/>
			) : !me.data.emailVerified ? (
				<VerifyEmailBanner />
			) : (
				<>
					<label className="grid gap-2 text-[13px] font-semibold text-muted">
						{vi.newGroup.nameLabel}
						<input
							ref={nameInput}
							value={name}
							onChange={(event) => setName(event.target.value)}
							maxLength={80}
							className="min-w-0 w-full h-[72px] rounded-[28px] bg-surface px-5 text-[26px] font-black text-ink"
						/>
					</label>
					<NewGroupMembers
						creatorName={me.data.name}
						names={names}
						onChange={setNames}
						isPending={create.isPending}
					/>
					<p className="text-[13px] text-muted">{vi.newGroup.hint}</p>
					<div className="mt-auto pt-5">
						{create.isError && (
							<p role="alert" className="mb-3">
								{vi.common.saveError}
							</p>
						)}
						<Button
							variant="accent"
							onClick={submit}
							disabled={!name.trim() || create.isPending}
							className="h-[68px] w-full rounded-[34px] text-[18px] font-black"
						>
							{names.length === 0
								? vi.newGroup.submitOne
								: t(vi.newGroup.submitMany, {
										count: String(names.length + 1),
									})}
						</Button>
					</div>
				</>
			)}
		</main>
	);
}
