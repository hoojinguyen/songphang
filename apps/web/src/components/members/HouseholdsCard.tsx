"use client";
import type { HouseholdDto, MemberDto } from "@songphang/contract";
import { useState } from "react";
import { useDeleteHousehold } from "../../lib/households";
import { t, vi } from "../../messages/vi";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";
import { HouseholdModal } from "./HouseholdModal";

export function HouseholdsCard({
	groupId,
	people,
	households,
	canWrite,
	isArchived,
}: {
	groupId: string;
	people: MemberDto[];
	households: HouseholdDto[];
	canWrite: boolean;
	isArchived: boolean;
}) {
	const deleteMutation = useDeleteHousehold(groupId);
	const [modalOpen, setModalOpen] = useState(false);
	const [editing, setEditing] = useState<HouseholdDto | null>(null);
	const [confirmUngroup, setConfirmUngroup] = useState<HouseholdDto | null>(
		null,
	);

	const assignedIds = new Set(households.flatMap((h) => h.memberIds));
	const unassignedActiveCount = people.filter(
		(m) => m.active && !assignedIds.has(m.id),
	).length;
	const canCreate =
		canWrite &&
		!isArchived &&
		unassignedActiveCount >= 2 &&
		households.length < 30;

	return (
		<section className="grid gap-3 rounded-[30px] bg-surface p-5">
			<div className="flex flex-wrap items-center justify-between gap-2">
				<div>
					<h2 className="text-base font-black text-ink">
						{vi.households.sectionTitle}
					</h2>
					<p className="mt-0.5 text-xs font-semibold text-muted">
						{vi.households.sectionHint}
					</p>
				</div>
				{canCreate && (
					<OnlineButton
						type="button"
						onClick={() => {
							setEditing(null);
							setModalOpen(true);
						}}
						className="min-h-11 rounded-pill bg-sunken px-3.5 text-xs font-extrabold text-ink"
					>
						{vi.households.createAction}
					</OnlineButton>
				)}
			</div>

			{households.length === 0 ? (
				<p className="text-xs font-semibold text-muted">
					{vi.households.empty}
				</p>
			) : (
				<div className="grid gap-2.5">
					{households.map((household) => {
						const members = household.memberIds.flatMap((id) => {
							const found = people.find((m) => m.id === id);
							return found ? [found] : [];
						});
						const rep = people.find(
							(m) => m.id === household.representativeMemberId,
						);

						return (
							<div
								key={household.id}
								className="grid gap-2.5 rounded-[22px] bg-bg p-3.5"
							>
								<div className="flex items-center justify-between gap-2">
									<div className="min-w-0 flex-1">
										<p className="truncate text-sm font-black text-ink">
											{household.name}
										</p>
										{rep && (
											<p className="text-xs font-semibold text-muted">
												{t(vi.households.representativeBadge, {
													name: rep.name,
												})}
											</p>
										)}
									</div>
									<div className="flex shrink-0 -space-x-2">
										{members.map((member) => (
											<MemberShape key={member.id} {...member} size={28} />
										))}
									</div>
								</div>

								{canWrite && !isArchived && (
									<div className="flex flex-wrap gap-2">
										<OnlineButton
											type="button"
											onClick={() => {
												setEditing(household);
												setModalOpen(true);
											}}
											className="min-h-11 rounded-pill bg-surface px-3.5 text-xs font-bold text-ink"
										>
											{vi.households.editAction}
										</OnlineButton>
										<OnlineButton
											type="button"
											onClick={() => setConfirmUngroup(household)}
											className="min-h-11 rounded-pill bg-debt-soft px-3.5 text-xs font-bold text-debt"
										>
											{vi.households.ungroupAction}
										</OnlineButton>
									</div>
								)}
							</div>
						);
					})}
				</div>
			)}

			<HouseholdModal
				open={modalOpen}
				groupId={groupId}
				people={people}
				households={households}
				editing={editing}
				onClose={() => setModalOpen(false)}
			/>

			{confirmUngroup && (
				<ConfirmDialog
					title={vi.households.ungroupAction}
					body={vi.households.ungroupConfirm}
					confirmLabel={vi.households.ungroupAction}
					cancelLabel={vi.common.cancel}
					confirmDisabled={deleteMutation.isPending}
					onConfirm={() => {
						deleteMutation.mutate(confirmUngroup.id, {
							onSuccess: () => setConfirmUngroup(null),
						});
					}}
					onCancel={() => setConfirmUngroup(null)}
				/>
			)}
		</section>
	);
}
