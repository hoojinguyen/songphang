"use client";
import { vi } from "../../messages/vi";
import { ConfirmDialog } from "../ui/ConfirmDialog";

export function ArchiveGroupDialog({
	open,
	groupName: _groupName,
	isPending,
	onConfirm,
	onCancel,
}: {
	open: boolean;
	groupName?: string;
	isPending?: boolean;
	onConfirm: () => void;
	onCancel: () => void;
}) {
	if (!open) return null;

	return (
		<ConfirmDialog
			title={vi.groups.archiveAction}
			body={vi.groups.archiveConfirmBody}
			confirmLabel={vi.groups.archiveAction}
			cancelLabel={vi.common.cancel}
			confirmDisabled={isPending ?? false}
			onConfirm={onConfirm}
			onCancel={onCancel}
		/>
	);
}
