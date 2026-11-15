"use client";
import type { GroupDto } from "@songphang/contract";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { Button } from "../../../../components/ui/Button";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { Switch } from "../../../../components/ui/Switch";
import { VerifyEmailBanner } from "../../../../components/ui/VerifyEmailBanner";
import { useGroup, useUpdateGroup } from "../../../../lib/groups";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";

function SettingsForm({ group }: { group: GroupDto }) {
	const [name, setName] = useState(group.name);
	const [minimizeDebts, setMinimizeDebts] = useState(group.minimizeDebts);
	const update = useUpdateGroup(group.id);
	useSessionGuard(update.error);
	const changeMode = (checked: boolean) => {
		const previous = minimizeDebts;
		setMinimizeDebts(checked);
		update.mutate(
			{ minimizeDebts: checked },
			{ onError: () => setMinimizeDebts(previous) },
		);
	};
	return (
		<>
			<label className="grid gap-2 text-[13px] font-semibold text-muted">
				{vi.settings.nameLabel}
				<input
					value={name}
					maxLength={80}
					onChange={(event) => setName(event.target.value)}
					className="h-16 min-w-0 w-full rounded-[26px] bg-surface px-5 text-[22px] font-black text-ink"
				/>
			</label>
			<Button
				variant="primary"
				disabled={
					update.isPending || !name.trim() || name.trim() === group.name
				}
				onClick={() => update.mutate({ name: name.trim() })}
			>
				{vi.settings.saveName}
			</Button>
			<section className="flex items-center gap-4 rounded-[28px] bg-surface p-5">
				<div className="min-w-0 flex-1">
					<h2 className="text-[15px] font-extrabold">
						{vi.settings.minimizeTitle}
					</h2>
					<p className="mt-1 text-xs text-muted">{vi.settings.minimizeHint}</p>
				</div>
				<Switch
					checked={minimizeDebts}
					onChange={changeMode}
					label={vi.settings.minimizeTitle}
					disabled={update.isPending}
				/>
			</section>
			{update.isError && <p role="alert">{vi.common.saveError}</p>}
		</>
	);
}
export default function SettingsPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const group = useGroup(groupId);
	const me = useMe();
	useSessionGuard(group.error ?? me.error);
	if (
		group.error?.status === 404 ||
		(group.data && group.data.role !== "owner")
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/" className="flex min-h-11 items-center justify-center">
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	if (me.isPending || group.isPending || group.error?.status === 401)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	if (me.isError || group.isError)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
					}}
					isRetrying={group.isFetching}
				/>
			</main>
		);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6">
			<ScreenHeader
				title={vi.settings.title}
				subtitle={vi.settings.ownerOnly}
				backHref={`/g/${groupId}/members`}
				backLabel={vi.common.back}
			/>
			{me.data.emailVerified ? (
				<SettingsForm group={group.data} />
			) : (
				<VerifyEmailBanner />
			)}
		</main>
	);
}
