"use client";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useCloneGroup } from "../../lib/groups";
import { vi } from "../../messages/vi";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { Switch } from "../ui/Switch";

function defaultCloneName(sourceName: string): string {
	const suffix = " (bản sao)";
	const maxBase = 80 - suffix.length;
	const base = sourceName.slice(0, maxBase).trim();
	return `${base}${suffix}`;
}

export function CloneGroupDialog({
	open,
	groupId,
	groupName,
	onClose,
}: {
	open: boolean;
	groupId: string;
	groupName: string;
	onClose: () => void;
}) {
	const router = useRouter();
	const [name, setName] = useState(() => defaultCloneName(groupName));
	const [copyPaymentMethods, setCopyPaymentMethods] = useState(true);
	const [copyCategories, setCopyCategories] = useState(false);
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const cloneMutation = useCloneGroup(groupId);

	if (!open) return null;

	const trimmed = name.trim();
	const isInvalid = !trimmed || trimmed.length > 80;

	const handleConfirm = () => {
		if (isInvalid) return;
		cloneMutation.mutate(
			{
				request: {
					name: trimmed,
					copyPaymentMethods,
					copyCategories,
				},
				key: idempotencyKey,
			},
			{
				onSuccess: (newGroup) => {
					onClose();
					router.push(`/g/${newGroup.id}`);
				},
			},
		);
	};

	return (
		<ConfirmDialog
			title={vi.clone.title}
			body=""
			confirmLabel={vi.clone.submit}
			cancelLabel={vi.common.cancel}
			confirmDisabled={cloneMutation.isPending || isInvalid}
			onConfirm={handleConfirm}
			onCancel={onClose}
		>
			<div className="grid gap-4 py-2">
				<label className="grid gap-1.5 text-xs font-semibold text-muted">
					{vi.clone.nameLabel}
					<input
						type="text"
						value={name}
						maxLength={80}
						disabled={cloneMutation.isPending}
						onChange={(e) => setName(e.target.value)}
						className="h-12 w-full rounded-[18px] bg-surface px-4 text-base font-bold text-ink"
					/>
				</label>
				<div className="flex items-center justify-between gap-3">
					<span className="text-xs font-semibold text-ink">
						{vi.clone.copyPaymentMethods}
					</span>
					<Switch
						checked={copyPaymentMethods}
						onChange={setCopyPaymentMethods}
						label={vi.clone.copyPaymentMethods}
						disabled={cloneMutation.isPending}
					/>
				</div>
				<div className="flex items-center justify-between gap-3">
					<span className="text-xs font-semibold text-ink">
						{vi.clone.copyCategories}
					</span>
					<Switch
						checked={copyCategories}
						onChange={setCopyCategories}
						label={vi.clone.copyCategories}
						disabled={cloneMutation.isPending}
					/>
				</div>
				{cloneMutation.isError && (
					<p role="alert" className="text-xs font-bold text-coral">
						{vi.common.saveError}
					</p>
				)}
			</div>
		</ConfirmDialog>
	);
}
