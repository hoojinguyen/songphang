"use client";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useGroupUserAction } from "../../lib/group-users";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
export function LeaveGroupButton({
	groupId,
	name,
}: {
	groupId: string;
	name: string;
}) {
	const action = useGroupUserAction(groupId);
	const router = useRouter();
	const [confirm, setConfirm] = useState(false);
	useSessionGuard(action.error);
	return (
		<>
			<Button variant="surface" size="lg" onClick={() => setConfirm(true)}>
				{vi.members.leave}
			</Button>
			{confirm && (
				<ConfirmDialog
					title={t(vi.members.leaveTitle, { name })}
					body={vi.members.leaveBody}
					confirmLabel={vi.members.leave}
					cancelLabel={vi.common.cancel}
					confirmDisabled={action.isPending}
					onCancel={() => setConfirm(false)}
					onConfirm={() =>
						action.mutate(
							{ action: "leave" },
							{ onSuccess: () => router.replace("/") },
						)
					}
				>
					{action.isError && (
						<p role="alert">
							{action.error.status === 403
								? vi.common.forbidden
								: vi.common.saveError}
						</p>
					)}
				</ConfirmDialog>
			)}
		</>
	);
}
