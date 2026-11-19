"use client";
import { useRef, useState } from "react";
import { useCreateComment } from "../../lib/comments";
import { useOnline } from "../../lib/use-online";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";

export function CommentField({
	groupId,
	transactionId,
	verified,
}: {
	groupId: string;
	transactionId: string;
	verified: boolean;
}) {
	const [body, setBody] = useState("");
	const keyRef = useRef<string>(crypto.randomUUID());
	const online = useOnline();
	const createMutation = useCreateComment(groupId, transactionId);

	if (!verified) return null;

	const trimmed = body.trim();
	const canSend = online && trimmed.length > 0 && !createMutation.isPending;

	const submit = () => {
		if (!canSend) return;
		createMutation.mutate(
			{ body: trimmed, key: keyRef.current },
			{
				onSuccess: () => {
					setBody("");
					keyRef.current = crypto.randomUUID();
				},
			},
		);
	};

	return (
		<div className="fixed bottom-0 left-1/2 w-full max-w-[430px] -translate-x-1/2 bg-bg px-5 pb-5 pt-3">
			{createMutation.isError && (
				<p role="alert" className="mb-1.5 text-xs font-bold">
					{vi.common.saveError}
				</p>
			)}
			<div className="flex items-end gap-2 rounded-[28px] border-2 border-ink bg-surface p-2">
				<textarea
					aria-label={vi.transactionView.commentPlaceholder}
					placeholder={vi.transactionView.commentPlaceholder}
					value={body}
					maxLength={1000}
					rows={1}
					disabled={!online}
					onChange={(event) => {
						setBody(event.target.value);
						keyRef.current = crypto.randomUUID();
					}}
					onKeyDown={(event) => {
						if (
							event.key === "Enter" &&
							!event.shiftKey &&
							!event.nativeEvent.isComposing
						) {
							event.preventDefault();
							submit();
						}
					}}
					className="min-h-11 max-h-32 min-w-0 flex-1 resize-none bg-transparent px-2 py-2.5 text-sm text-ink outline-none"
				/>
				<button
					type="button"
					aria-label={vi.transactionView.send}
					disabled={!canSend}
					onClick={submit}
					className="flex size-11 shrink-0 items-center justify-center rounded-[20px] bg-ink text-surface disabled:bg-sunken disabled:text-muted"
				>
					<Icon name="send" size={20} />
				</button>
			</div>
		</div>
	);
}
