"use client";
import type { GroupDto } from "@songphang/contract";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { ArchiveGroupDialog } from "../../../../components/groups/ArchiveGroupDialog";
import { CloneGroupDialog } from "../../../../components/groups/CloneGroupDialog";
import { ApprovalCard } from "../../../../components/settings/ApprovalCard";
import { BudgetCard } from "../../../../components/settings/BudgetCard";
import { CategoryList } from "../../../../components/settings/CategoryList";
import { DeleteGroupCard } from "../../../../components/settings/DeleteGroupCard";
import { InviteLinkCard } from "../../../../components/settings/InviteLinkCard";
import { TelegramCard } from "../../../../components/settings/TelegramCard";
import { TransferOwnershipCard } from "../../../../components/settings/TransferOwnershipCard";
import { Button } from "../../../../components/ui/Button";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { SegmentedControl } from "../../../../components/ui/SegmentedControl";
import { Switch } from "../../../../components/ui/Switch";
import { VerifyEmailBanner } from "../../../../components/ui/VerifyEmailBanner";
import {
	useArchiveGroup,
	useGroup,
	useUnarchiveGroup,
	useUpdateGroup,
} from "../../../../lib/groups";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";

function SettingsForm({ group }: { group: GroupDto }) {
	const [name, setName] = useState(group.name);
	const [minimizeDebts, setMinimizeDebts] = useState(group.minimizeDebts);
	const [archiveOpen, setArchiveOpen] = useState(false);
	const [cloneOpen, setCloneOpen] = useState(false);
	const update = useUpdateGroup(group.id);
	const archiveMutation = useArchiveGroup(group.id);
	const unarchiveMutation = useUnarchiveGroup(group.id);
	const actionError =
		update.error ?? archiveMutation.error ?? unarchiveMutation.error;
	const isArchived = group.archivedAt !== null;
	useSessionGuard(actionError);
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
			{isArchived && (
				<div
					role="status"
					className="rounded-[22px] bg-sunken px-4 py-3 text-sm font-bold text-ink"
				>
					{vi.groups.archivedBanner}
				</div>
			)}
			<label className="grid gap-2 text-[13px] font-semibold text-muted">
				{vi.settings.nameLabel}
				<input
					value={name}
					maxLength={80}
					disabled={isArchived || update.isPending}
					onChange={(event) => setName(event.target.value)}
					className="h-16 min-w-0 w-full rounded-[26px] bg-surface px-5 text-[22px] font-black text-ink disabled:opacity-60"
				/>
			</label>
			<Button
				variant="primary"
				disabled={
					isArchived ||
					update.isPending ||
					!name.trim() ||
					name.trim() === group.name
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
					disabled={isArchived || update.isPending}
				/>
			</section>
			<section className="grid gap-3 rounded-[28px] bg-surface p-5">
				<h2 className="font-extrabold">{vi.settings.defaultRoleTitle}</h2>
				<p className="text-xs text-muted">{vi.settings.defaultRoleHint}</p>
				<SegmentedControl
					label={vi.settings.defaultRoleTitle}
					value={group.defaultRole}
					options={[
						{ value: "editor", label: vi.members.roleEditor },
						{ value: "viewer", label: vi.members.roleViewer },
					]}
					disabled={isArchived || update.isPending}
					onChange={(defaultRole) => {
						if (defaultRole === "editor" || defaultRole === "viewer")
							update.mutate({ defaultRole });
					}}
				/>
			</section>
			<section className="grid gap-3 rounded-[28px] bg-surface p-5">
				<h2 className="font-extrabold">{vi.reminders.settingTitle}</h2>
				<SegmentedControl
					label={vi.reminders.settingTitle}
					value={
						group.reminderIntervalDays === null
							? "off"
							: String(group.reminderIntervalDays)
					}
					options={[
						{ value: "off", label: vi.reminders.intervalOff },
						{ value: "3", label: vi.reminders.interval3 },
						{ value: "7", label: vi.reminders.interval7 },
						{ value: "14", label: vi.reminders.interval14 },
					]}
					disabled={isArchived || update.isPending}
					onChange={(value) => {
						const reminderIntervalDays =
							value === "3"
								? 3
								: value === "7"
									? 7
									: value === "14"
										? 14
										: null;
						update.mutate({ reminderIntervalDays });
					}}
				/>
			</section>
			<ApprovalCard group={group} />
			<BudgetCard groupId={group.id} />
			<CategoryList groupId={group.id} />
			<InviteLinkCard groupId={group.id} />
			<TelegramCard groupId={group.id} />
			<TransferOwnershipCard groupId={group.id} />
			<section className="flex items-center justify-between gap-4 rounded-[28px] bg-surface p-5">
				<div>
					<h2 className="text-[15px] font-extrabold">{vi.clone.title}</h2>
				</div>
				<Button variant="surface" onClick={() => setCloneOpen(true)}>
					{vi.clone.title}
				</Button>
			</section>
			{group.archivedAt ? (
				<section className="flex items-center justify-between gap-4 rounded-[28px] bg-surface p-5">
					<div>
						<h2 className="text-[15px] font-extrabold">
							{vi.groups.unarchiveAction}
						</h2>
					</div>
					<Button
						variant="primary"
						disabled={unarchiveMutation.isPending}
						onClick={() => unarchiveMutation.mutate()}
					>
						{vi.groups.unarchiveAction}
					</Button>
				</section>
			) : (
				<section className="flex items-center justify-between gap-4 rounded-[28px] bg-surface p-5">
					<div>
						<h2 className="text-[15px] font-extrabold">
							{vi.groups.archiveAction}
						</h2>
					</div>
					<Button variant="surface" onClick={() => setArchiveOpen(true)}>
						{vi.groups.archiveAction}
					</Button>
				</section>
			)}
			<ArchiveGroupDialog
				open={archiveOpen}
				groupName={group.name}
				isPending={archiveMutation.isPending}
				onConfirm={() => {
					archiveMutation.mutate(undefined, {
						onSuccess: () => setArchiveOpen(false),
						onError: () => setArchiveOpen(false),
					});
				}}
				onCancel={() => setArchiveOpen(false)}
			/>
			<CloneGroupDialog
				open={cloneOpen}
				groupId={group.id}
				groupName={group.name}
				onClose={() => setCloneOpen(false)}
			/>
			<DeleteGroupCard group={group} />
			{actionError && (
				<p role="alert" className="text-sm font-bold text-debt">
					{actionError.status === 403
						? vi.common.forbidden
						: actionError.status === 409
							? vi.groups.archivedReadOnlyError
							: vi.common.saveError}
				</p>
			)}
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
				<p>
					{group.error?.status === 404
						? vi.common.groupNotFound
						: vi.common.forbidden}
				</p>
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
	if ((me.isError && !me.data) || (group.isError && !group.data))
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
