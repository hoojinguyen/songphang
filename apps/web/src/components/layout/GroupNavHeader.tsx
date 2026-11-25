"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { useArchiveGroup, useGroup, useUnarchiveGroup } from "../../lib/groups";
import { useMembers } from "../../lib/members";
import { vi } from "../../messages/vi";
import { ArchiveGroupDialog } from "../groups/ArchiveGroupDialog";
import { CloneGroupDialog } from "../groups/CloneGroupDialog";
import { Bell } from "../notifications/Bell";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";

export function GroupNavHeader({ groupId }: { groupId: string }) {
	const pathname = usePathname();
	const groupQuery = useGroup(groupId);
	const membersQuery = useMembers(groupId);
	const group = groupQuery.data;
	const members = membersQuery.data ?? [];

	const [menuOpen, setMenuOpen] = useState(false);
	const [archiveOpen, setArchiveOpen] = useState(false);
	const [cloneOpen, setCloneOpen] = useState(false);

	const archiveMutation = useArchiveGroup(groupId);
	const unarchiveMutation = useUnarchiveGroup(groupId);

	if (!group) return null;

	const isArchived = Boolean(group.archivedAt);

	const isFeed = pathname === `/g/${groupId}`;
	const isBalances = pathname === `/g/${groupId}/balances`;
	const isStatsOrFund =
		pathname === `/g/${groupId}/stats` || pathname === `/g/${groupId}/fund`;

	const segments = [
		{
			id: "expenses",
			label: vi.groupSegments.expenses,
			href: `/g/${groupId}`,
			active: isFeed,
		},
		{
			id: "payments",
			label: vi.groupSegments.payments,
			href: `/g/${groupId}/balances`,
			active: isBalances,
		},
		{
			id: "fundAndStats",
			label: vi.groupSegments.fundAndStats,
			href: `/g/${groupId}/stats`,
			active: isStatsOrFund,
		},
	];

	return (
		<div className="flex flex-col gap-3">
			{/* Top Header Row */}
			<header className="flex items-center justify-between gap-3">
				<div className="flex items-center gap-2 min-w-0">
					<Link
						href="/groups"
						aria-label={vi.common.back}
						className="flex size-11 shrink-0 items-center justify-center rounded-pill bg-surface text-ink transition-colors hover:bg-surface-raised"
					>
						<Icon name="back" size={22} />
					</Link>
					<div className="flex items-center gap-2 min-w-0">
						<h1 className="truncate text-lg font-black text-ink">
							{group.name}
						</h1>
						{isArchived && (
							<span className="shrink-0 rounded-pill bg-sunken px-2 py-0.5 text-xs font-bold text-muted">
								{vi.groups.tabArchived}
							</span>
						)}
					</div>
				</div>

				<div className="flex items-center gap-2 shrink-0">
					<Bell />
					<Link
						href={`/g/${groupId}/members`}
						aria-label={vi.feed.membersLink}
						className="flex h-11 items-center rounded-pill bg-surface px-2.5 transition-colors hover:bg-surface-raised"
					>
						{members
							.filter((m) => m.kind === "person")
							.slice(0, 4)
							.map((m) => (
								<MemberShape key={m.id} {...m} size={24} />
							))}
					</Link>

					{/* Overflow menu button */}
					<div className="relative">
						<button
							type="button"
							aria-label={vi.settings.title}
							onClick={() => setMenuOpen((o) => !o)}
							className="flex size-11 items-center justify-center rounded-pill bg-surface text-ink transition-colors hover:bg-surface-raised"
						>
							<Icon name="dots-horizontal" size={20} />
						</button>

						{menuOpen && (
							<>
								<button
									type="button"
									aria-label={vi.common.cancel}
									className="fixed inset-0 z-30 cursor-default bg-transparent"
									onClick={() => setMenuOpen(false)}
								/>
								<div className="absolute right-0 top-12 z-40 w-52 rounded-[20px] border border-sunken bg-bg p-2 shadow-lg">
									<Link
										href={`/g/${groupId}/activity`}
										onClick={() => setMenuOpen(false)}
										className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
									>
										{vi.activity.title}
									</Link>
									{group.role === "owner" && (
										<>
											<Link
												href={`/g/${groupId}/settings`}
												onClick={() => setMenuOpen(false)}
												className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
											>
												{vi.categories.title}
											</Link>
											<Link
												href={`/g/${groupId}/settings`}
												onClick={() => setMenuOpen(false)}
												className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
											>
												{vi.telegram.settingsTitle}
											</Link>
										</>
									)}
									{group.role !== "viewer" && (
										<button
											type="button"
											onClick={() => {
												setMenuOpen(false);
												setCloneOpen(true);
											}}
											className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
										>
											{vi.clone.title}
										</button>
									)}
									{group.role === "owner" && (
										<>
											{isArchived ? (
												<button
													type="button"
													onClick={() => {
														setMenuOpen(false);
														unarchiveMutation.mutate();
													}}
													disabled={unarchiveMutation.isPending}
													className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
												>
													{vi.groups.unarchiveAction}
												</button>
											) : (
												<button
													type="button"
													onClick={() => {
														setMenuOpen(false);
														setArchiveOpen(true);
													}}
													className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
												>
													{vi.groups.archiveAction}
												</button>
											)}
											<Link
												href={`/g/${groupId}/settings`}
												onClick={() => setMenuOpen(false)}
												className="flex w-full items-center rounded-[14px] px-3 py-2 text-xs font-bold text-ink hover:bg-surface"
											>
												{vi.settings.title}
											</Link>
										</>
									)}
								</div>
							</>
						)}
					</div>
				</div>
			</header>

			{/* 3-Segment Switcher */}
			<nav
				aria-label={vi.groups.title}
				className="flex rounded-[20px] bg-sunken p-1"
			>
				{segments.map((seg) => (
					<Link
						key={seg.id}
						href={seg.href}
						aria-current={seg.active ? "page" : undefined}
						className={`flex h-10 flex-1 items-center justify-center rounded-[16px] text-xs font-extrabold transition-all ${
							seg.active
								? "bg-ink text-on-ink shadow-sm"
								: "text-muted hover:text-ink"
						}`}
					>
						{seg.label}
					</Link>
				))}
			</nav>

			{/* Archived banner notice if archived */}
			{isArchived && (
				<div className="rounded-[16px] bg-sunken px-3.5 py-2 text-center text-xs font-bold text-muted">
					{vi.groups.archivedBanner}
				</div>
			)}

			<ArchiveGroupDialog
				open={archiveOpen}
				groupName={group.name}
				isPending={archiveMutation.isPending}
				onConfirm={() => {
					archiveMutation.mutate(undefined, {
						onSuccess: () => setArchiveOpen(false),
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
		</div>
	);
}
