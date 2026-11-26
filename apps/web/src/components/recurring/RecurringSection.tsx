"use client";
import type {
	CategoryDto,
	MemberDto,
	RecurringExpenseDto,
} from "@songphang/contract";
import Link from "next/link";
import { useState } from "react";
import { formatMoney } from "../../lib/money";
import {
	formatCalendarDateVN,
	formatRecurringScheduleSummary,
	useDeleteRecurringExpense,
	useRecurringExpenses,
	useSkipRecurringExpense,
	useUpdateRecurringExpense,
} from "../../lib/recurring-expenses";
import { t, vi } from "../../messages/vi";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { OnlineButton } from "../ui/OnlineButton";
import { RecurringFormModal } from "./RecurringFormModal";

export function RecurringSection({
	groupId,
	members,
	categories,
	myMemberId,
	canWrite,
	isArchived,
}: {
	groupId: string;
	members: MemberDto[];
	categories: CategoryDto[];
	myMemberId: string | null;
	canWrite: boolean;
	isArchived: boolean;
}) {
	const recurringQuery = useRecurringExpenses(groupId);
	const updateMutation = useUpdateRecurringExpense(groupId);
	const skipMutation = useSkipRecurringExpense(groupId);
	const deleteMutation = useDeleteRecurringExpense(groupId);

	const [modalOpen, setModalOpen] = useState(false);
	const [editing, setEditing] = useState<RecurringExpenseDto | null>(null);
	const [confirmDelete, setConfirmDelete] =
		useState<RecurringExpenseDto | null>(null);

	const items = recurringQuery.data ?? [];
	const dueItems = items.filter((item) => item.pendingDueDate !== null);

	const memberName = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;

	const splitLabel = (split: RecurringExpenseDto["splitTemplate"]) => {
		switch (split.method) {
			case "equal":
				return vi.split.methodEqual;
			case "exact":
				return vi.split.methodExact;
			case "shares":
				return vi.split.methodShares;
			case "percent":
				return vi.split.methodPercent;
			case "items":
				return vi.split.methodItems;
		}
	};

	const openCreate = () => {
		setEditing(null);
		setModalOpen(true);
	};

	const openEdit = (item: RecurringExpenseDto) => {
		setEditing(item);
		setModalOpen(true);
	};

	return (
		<section className="grid gap-3 rounded-card bg-surface p-4">
			<div className="flex items-center justify-between gap-2 px-1">
				<h2 className="text-sm font-extrabold text-ink">
					{vi.recurring.sectionTitle}
				</h2>
				{canWrite && !isArchived && (
					<OnlineButton
						type="button"
						onClick={openCreate}
						className="min-h-11 rounded-pill bg-sunken px-3.5 text-xs font-extrabold text-ink"
					>
						{vi.recurring.createAction}
					</OnlineButton>
				)}
			</div>

			{dueItems.length > 0 && (
				<div className="grid gap-2">
					{dueItems.map((item) => (
						<div
							key={`due-${item.id}`}
							className="grid gap-2 rounded-[22px] bg-warning-soft p-3.5 text-ink"
						>
							<div className="flex items-start justify-between gap-2">
								<div className="min-w-0">
									<p className="text-xs font-extrabold text-warning">
										{t(vi.recurring.pendingDueTemplate, {
											date: formatCalendarDateVN(item.pendingDueDate ?? ""),
										})}
									</p>
									<p className="truncate text-sm font-black">
										{item.description}
									</p>
								</div>
								{item.amount !== null && (
									<span className="shrink-0 tabular-nums text-sm font-black">
										{formatMoney(item.amount)}
									</span>
								)}
							</div>
							{canWrite && !isArchived && (
								<div className="flex flex-wrap gap-2">
									<Link
										href={`/g/${encodeURIComponent(groupId)}/tx/new?form=1&recurringId=${encodeURIComponent(item.id)}`}
										className="flex min-h-11 items-center justify-center rounded-pill bg-ink px-4 text-xs font-extrabold text-on-ink"
									>
										{vi.recurring.enterAmount}
									</Link>
									<OnlineButton
										type="button"
										disabled={skipMutation.isPending}
										onClick={() => skipMutation.mutate(item.id)}
										className="min-h-11 rounded-pill bg-surface px-4 text-xs font-bold text-ink"
									>
										{vi.recurring.skipThisPeriod}
									</OnlineButton>
								</div>
							)}
						</div>
					))}
				</div>
			)}

			{recurringQuery.isPending ? (
				<div className="h-16 rounded-[20px] bg-sunken" aria-busy="true" />
			) : items.length === 0 ? (
				<p className="px-1 py-2 text-xs font-semibold text-muted">
					{vi.recurring.empty}
				</p>
			) : (
				<div className="grid gap-2">
					{items.map((item) => {
						const payerSummary = item.payersTemplate
							.map((p) => memberName(p.memberId))
							.join(" · ");
						return (
							<div
								key={item.id}
								className="grid gap-2 rounded-[22px] bg-bg p-3.5"
							>
								<div className="flex items-start justify-between gap-2">
									<div className="min-w-0 flex-1">
										<div className="flex flex-wrap items-center gap-1.5">
											<span
												className={`rounded-pill px-2.5 py-0.5 text-[11px] font-extrabold ${
													!item.active
														? "bg-sunken text-muted"
														: item.mode === "fixed"
															? "bg-credit-soft text-credit"
															: "bg-warning-soft text-warning"
												}`}
											>
												{!item.active
													? vi.recurring.pausedBadge
													: item.mode === "fixed"
														? vi.recurring.modeFixed
														: vi.recurring.modeVariable}
											</span>
											<span className="truncate text-sm font-black text-ink">
												{item.description}
											</span>
										</div>
										<p className="mt-1 text-xs font-semibold text-muted">
											{formatRecurringScheduleSummary(item)}
										</p>
										<p className="text-xs text-muted">
											{t(vi.compose.payer, { name: payerSummary })} ·{" "}
											{splitLabel(item.splitTemplate)}
										</p>
										{!item.active && item.pauseReason === "member_invalid" && (
											<p className="mt-1 text-xs font-bold text-warning">
												{vi.recurring.pausedMemberInvalid}
											</p>
										)}
									</div>
									{item.amount !== null && (
										<p className="shrink-0 tabular-nums text-sm font-black text-ink">
											{formatMoney(item.amount)}
										</p>
									)}
								</div>

								{canWrite && (
									<div className="flex flex-wrap gap-1.5">
										{!isArchived && (
											<>
												<OnlineButton
													type="button"
													onClick={() => openEdit(item)}
													className="min-h-11 rounded-pill bg-surface px-3 text-xs font-bold text-ink"
												>
													{vi.households.editAction}
												</OnlineButton>
												<OnlineButton
													type="button"
													disabled={updateMutation.isPending}
													onClick={() =>
														updateMutation.mutate({
															recurringId: item.id,
															request: { active: !item.active },
														})
													}
													className="min-h-11 rounded-pill bg-surface px-3 text-xs font-bold text-ink"
												>
													{item.active
														? vi.recurring.pause
														: vi.recurring.resume}
												</OnlineButton>
												{item.active && item.pendingDueDate === null && (
													<OnlineButton
														type="button"
														disabled={skipMutation.isPending}
														onClick={() => skipMutation.mutate(item.id)}
														className="min-h-11 rounded-pill bg-surface px-3 text-xs font-bold text-ink"
													>
														{vi.recurring.skipNextPeriod}
													</OnlineButton>
												)}
											</>
										)}
										<OnlineButton
											type="button"
											onClick={() => setConfirmDelete(item)}
											className="min-h-11 rounded-pill bg-debt-soft px-3 text-xs font-bold text-debt"
										>
											{vi.recurring.deleteAction}
										</OnlineButton>
									</div>
								)}
							</div>
						);
					})}
				</div>
			)}

			<RecurringFormModal
				open={modalOpen}
				groupId={groupId}
				members={members}
				categories={categories}
				myMemberId={myMemberId}
				editing={editing}
				onClose={() => setModalOpen(false)}
			/>

			{confirmDelete && (
				<ConfirmDialog
					title={vi.recurring.deleteAction}
					body={confirmDelete.description}
					confirmLabel={vi.recurring.deleteAction}
					cancelLabel={vi.common.cancel}
					confirmDisabled={deleteMutation.isPending}
					onConfirm={() => {
						deleteMutation.mutate(confirmDelete.id, {
							onSuccess: () => setConfirmDelete(null),
						});
					}}
					onCancel={() => setConfirmDelete(null)}
				/>
			)}
		</section>
	);
}
