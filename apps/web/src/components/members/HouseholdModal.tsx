"use client";
import {
	CreateHouseholdRequest,
	type HouseholdDto,
	type MemberDto,
	UpdateHouseholdRequest,
} from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import { useCreateHousehold, useUpdateHousehold } from "../../lib/households";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";

export function HouseholdModal({
	open,
	groupId,
	people,
	households,
	editing,
	onClose,
}: {
	open: boolean;
	groupId: string;
	people: MemberDto[];
	households: HouseholdDto[];
	editing: HouseholdDto | null;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) dialog.showModal();
		else if (!open && dialog.open) dialog.close();
	}, [open]);

	if (!open) return <dialog ref={dialogRef} className="hidden" />;

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto max-h-[88dvh] w-[calc(100%-24px)] max-w-[430px] overflow-hidden rounded-[30px] bg-bg p-0 text-ink backdrop:bg-ink/45"
		>
			<HouseholdFormBody
				key={editing?.id ?? "new"}
				titleId={titleId}
				groupId={groupId}
				people={people}
				households={households}
				editing={editing}
				onClose={onClose}
			/>
		</dialog>
	);
}

function HouseholdFormBody({
	titleId,
	groupId,
	people,
	households,
	editing,
	onClose,
}: {
	titleId: string;
	groupId: string;
	people: MemberDto[];
	households: HouseholdDto[];
	editing: HouseholdDto | null;
	onClose: () => void;
}) {
	const [name, setName] = useState(editing?.name ?? "");
	const [selectedIds, setSelectedIds] = useState<string[]>(
		editing?.memberIds ?? [],
	);
	const [representativeMemberId, setRepresentativeMemberId] = useState<string>(
		editing?.representativeMemberId ?? "",
	);
	const [idempotencyKey] = useState(() => crypto.randomUUID());

	const createMutation = useCreateHousehold(groupId);
	const updateMutation = useUpdateHousehold(groupId);
	const mutation = editing ? updateMutation : createMutation;

	const occupiedByOther = new Set(
		households.filter((h) => h.id !== editing?.id).flatMap((h) => h.memberIds),
	);
	const eligibleMembers = people.filter(
		(member) =>
			!occupiedByOther.has(member.id) &&
			(member.active || editing?.memberIds.includes(member.id)),
	);
	const selectedActiveMembers = eligibleMembers.filter(
		(member) => selectedIds.includes(member.id) && member.active,
	);

	const toggleMember = (id: string) => {
		setSelectedIds((current) => {
			const exists = current.includes(id);
			const next = exists
				? current.filter((item) => item !== id)
				: current.length >= 20
					? current
					: [...current, id];
			if (exists && representativeMemberId === id) {
				const fallback = eligibleMembers.find(
					(m) => next.includes(m.id) && m.active,
				);
				setRepresentativeMemberId(fallback?.id ?? "");
			} else if (!exists && !representativeMemberId) {
				const picked = eligibleMembers.find((m) => m.id === id);
				if (picked?.active) setRepresentativeMemberId(picked.id);
			}
			return next;
		});
	};

	const validated = CreateHouseholdRequest.safeParse({
		name: name.trim(),
		memberIds: selectedIds,
		representativeMemberId,
	});
	const repIsActive = selectedActiveMembers.some(
		(m) => m.id === representativeMemberId,
	);

	const errorMessage = mutation.isError
		? mutation.error.code === "HOUSEHOLD_MEMBER_CONFLICT"
			? vi.households.conflictError
			: mutation.error.code === "HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED"
				? vi.households.repActiveError
				: mutation.error.status === 403
					? vi.common.forbidden
					: vi.common.saveError
		: null;

	const handleSubmit = () => {
		if (!validated.success || !repIsActive || mutation.isPending) return;
		if (editing) {
			const updateBody = UpdateHouseholdRequest.parse(validated.data);
			updateMutation.mutate(
				{ householdId: editing.id, request: updateBody },
				{ onSuccess: onClose },
			);
			return;
		}
		createMutation.mutate(
			{ request: validated.data, key: idempotencyKey },
			{ onSuccess: onClose },
		);
	};

	return (
		<div className="flex max-h-[88dvh] flex-col">
			<div className="flex items-center justify-between gap-3 border-b border-sunken px-5 py-4">
				<h2 id={titleId} className="truncate text-base font-black">
					{editing ? vi.households.editTitle : vi.households.createTitle}
				</h2>
				<button
					type="button"
					aria-label={vi.common.cancel}
					onClick={onClose}
					className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-surface text-ink"
				>
					<Icon name="close" size={18} />
				</button>
			</div>

			<div className="flex-1 space-y-4 overflow-y-auto p-5">
				<label className="grid gap-1 text-xs font-bold text-muted">
					{vi.households.nameLabel}
					<input
						type="text"
						maxLength={50}
						value={name}
						onChange={(event) => setName(event.target.value)}
						placeholder={vi.households.namePlaceholder}
						className="h-12 rounded-[18px] bg-surface px-4 text-sm font-bold text-ink"
					/>
				</label>

				<div className="grid gap-2">
					<p className="text-xs font-bold text-muted">
						{vi.households.membersLabel} ({selectedIds.length})
					</p>
					<div className="grid gap-1.5">
						{eligibleMembers.map((member) => {
							const checked = selectedIds.includes(member.id);
							return (
								<OnlineButton
									key={member.id}
									type="button"
									allowOffline
									aria-pressed={checked}
									onClick={() => toggleMember(member.id)}
									className={`flex min-h-12 items-center justify-between gap-3 rounded-[20px] px-3.5 py-2 text-left transition-colors ${
										checked ? "bg-ink text-on-ink" : "bg-surface text-ink"
									}`}
								>
									<span className="flex min-w-0 items-center gap-2.5">
										<MemberShape {...member} size={28} />
										<span className="truncate text-sm font-extrabold">
											{member.name}
										</span>
									</span>
									{member.paymentMethods.length > 0 && (
										<span
											className={`shrink-0 rounded-pill px-2 py-0.5 text-[10px] font-extrabold ${
												checked
													? "bg-accent text-on-accent"
													: "bg-credit-soft text-credit"
											}`}
										>
											{vi.households.hasVietQrHint}
										</span>
									)}
								</OnlineButton>
							);
						})}
					</div>
				</div>

				{selectedActiveMembers.length > 0 && (
					<div className="grid gap-2">
						<p className="text-xs font-bold text-muted">
							{vi.households.representativeLabel}
						</p>
						<div className="flex flex-wrap gap-2">
							{selectedActiveMembers.map((member) => {
								const picked = representativeMemberId === member.id;
								return (
									<OnlineButton
										key={member.id}
										type="button"
										allowOffline
										aria-pressed={picked}
										onClick={() => setRepresentativeMemberId(member.id)}
										className={`flex min-h-11 items-center gap-2 rounded-pill px-3 text-xs font-extrabold ${
											picked
												? "bg-accent text-on-accent"
												: "bg-surface text-ink"
										}`}
									>
										<MemberShape {...member} size={22} />
										<span>{member.name}</span>
										{member.paymentMethods.length > 0 && (
											<span className="rounded-pill bg-credit-soft px-1.5 py-0.5 text-[10px] font-bold text-credit">
												{vi.households.hasVietQrHint}
											</span>
										)}
									</OnlineButton>
								);
							})}
						</div>
					</div>
				)}

				{errorMessage && (
					<p role="alert" className="text-xs font-bold text-debt">
						{errorMessage}
					</p>
				)}
			</div>

			<div className="border-t border-sunken p-4">
				<Button
					type="button"
					variant="accent"
					size="lg"
					disabled={!validated.success || !repIsActive || mutation.isPending}
					onClick={handleSubmit}
					className="w-full"
				>
					{vi.households.saveAction}
				</Button>
			</div>
		</div>
	);
}
