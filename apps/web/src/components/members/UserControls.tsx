"use client";
import type { GroupUserDto } from "@songphang/contract";
import { useState } from "react";
import { useGroupUserAction } from "../../lib/group-users";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { SegmentedControl } from "../ui/SegmentedControl";
export function UserControls({
	groupId,
	user,
}: {
	groupId: string;
	user: GroupUserDto;
}) {
	const action = useGroupUserAction(groupId);
	const [confirm, setConfirm] = useState(false);
	useSessionGuard(action.error);
	return (
		<div className="grid gap-3 rounded-[28px] bg-surface p-4">
			<SegmentedControl
				label={t(vi.members.roleLabel, { name: user.name })}
				options={[
					{ value: "editor", label: vi.members.roleEditor },
					{ value: "viewer", label: vi.members.roleViewer },
				]}
				value={user.role}
				onChange={(role) => {
					if (role === "editor" || role === "viewer")
						action.mutate({ action: "role", userId: user.userId, role });
				}}
				disabled={action.isPending}
			/>
			<Button variant="surface" onClick={() => setConfirm(true)}>
				{vi.members.removeUser}
			</Button>
			{action.isError && (
				<p role="alert">
					{action.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
			{confirm && (
				<ConfirmDialog
					title={t(vi.members.removeTitle, { name: user.name })}
					body={vi.members.removeBody}
					confirmLabel={vi.members.removeConfirm}
					cancelLabel={vi.members.removeCancel}
					confirmDisabled={action.isPending}
					onCancel={() => setConfirm(false)}
					onConfirm={() =>
						action.mutate(
							{ action: "remove", userId: user.userId },
							{ onSuccess: () => setConfirm(false) },
						)
					}
				/>
			)}
		</div>
	);
}
