"use client";
import type { GroupDto } from "@songphang/contract";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { type ApiError, apiSend } from "../../lib/api";
import { jsonRequest } from "../../lib/request";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { TextField } from "../ui/TextField";
export function DeleteGroupCard({ group }: { group: GroupDto }) {
	const [open, setOpen] = useState(false);
	const [name, setName] = useState("");
	const client = useQueryClient();
	const router = useRouter();
	const deletion = useMutation<void, ApiError>({
		mutationFn: () =>
			apiSend(`/groups/${group.id}`, jsonRequest("DELETE", { name })),
		onMutate: () => {
			client.setQueryData(["deleting", group.id], true);
		},
		onError: () => client.removeQueries({ queryKey: ["deleting", group.id] }),
		onSuccess: async () => {
			await client.cancelQueries({ queryKey: ["group", group.id] });
			client.removeQueries({ queryKey: ["group", group.id] });
			client.removeQueries({ queryKey: ["deleting", group.id] });
			client.setQueryData(["notice", "deleted"], true);
			void client.invalidateQueries({ queryKey: ["groups"] });
			router.replace("/");
		},
	});
	return (
		<section className="grid gap-3 rounded-[28px] bg-debt-soft p-5">
			<p className="text-xs font-semibold">{vi.settings.deleteHint}</p>
			<Button
				variant="primary"
				onClick={() => {
					setName("");
					setOpen(true);
				}}
			>
				{vi.settings.deleteButton}
			</Button>
			{open && (
				<ConfirmDialog
					title={t(vi.settings.deleteTitle, { name: group.name })}
					body={vi.settings.deleteBody}
					confirmLabel={vi.settings.deleteButton}
					cancelLabel={vi.members.removeCancel}
					onCancel={() => {
						if (!deletion.isPending) setOpen(false);
					}}
					onConfirm={() => {
						if (name === group.name && !deletion.isPending) deletion.mutate();
					}}
					confirmDisabled={name !== group.name || deletion.isPending}
				>
					<TextField
						label={vi.settings.nameLabel}
						value={name}
						maxLength={80}
						onChange={(e) => setName(e.target.value)}
					/>
					{deletion.isError && <p role="alert">{vi.common.saveError}</p>}
				</ConfirmDialog>
			)}
		</section>
	);
}
