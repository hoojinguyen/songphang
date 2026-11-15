"use client";
import type { GroupUserDto } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useGroupUserAction, useGroupUsers } from "../../lib/group-users";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { LoadError } from "../ui/LoadError";
export function TransferOwnershipCard({ groupId }: { groupId: string }) {
	const users = useGroupUsers(groupId);
	const action = useGroupUserAction(groupId);
	const router = useRouter();
	const [target, setTarget] = useState<GroupUserDto | null>(null);
	useSessionGuard(users.error ?? action.error);
	if (users.isPending)
		return <div aria-busy="true" className="h-40 rounded-card bg-sunken" />;
	if (users.isError)
		return (
			<LoadError
				onRetry={() => {
					void users.refetch();
				}}
				isRetrying={users.isFetching}
			/>
		);
	const others = users.data.filter((user) => !user.isMe);
	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.settings.transferTitle}</h2>
			<p className="text-xs text-muted">{vi.settings.transferHint}</p>
			{others.length === 0 ? (
				<p>{vi.settings.transferNobody}</p>
			) : (
				others.map((user) => (
					<Button
						key={user.userId}
						variant="surface"
						className="bg-bg"
						onClick={() => setTarget(user)}
					>
						{user.name}
					</Button>
				))
			)}
			{target && (
				<ConfirmDialog
					title={t(vi.settings.transferConfirmTitle, { name: target.name })}
					body={vi.settings.transferConfirmBody}
					confirmLabel={vi.settings.transferConfirm}
					cancelLabel={vi.common.cancel}
					confirmDisabled={action.isPending}
					onCancel={() => setTarget(null)}
					onConfirm={() =>
						action.mutate(
							{ action: "transfer", userId: target.userId },
							{
								onSuccess: () => {
									setTarget(null);
									router.replace(`/g/${groupId}/members`);
								},
							},
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
		</section>
	);
}
