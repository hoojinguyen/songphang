"use client";
import type { CommentDto, GroupRole } from "@songphang/contract";
import { formatVietnamDateTime } from "@songphang/core";
import { useDeleteComment } from "../../lib/comments";
import { useOnline } from "../../lib/use-online";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";

export function CommentThread({
	groupId,
	transactionId,
	comments,
	role,
	verified,
	isPending,
	isError,
	isFetching,
	hasNextPage,
	isFetchingNextPage,
	onRetry,
	onLoadMore,
}: {
	groupId: string;
	transactionId: string;
	comments: CommentDto[];
	role: GroupRole;
	verified: boolean;
	isPending: boolean;
	isError: boolean;
	isFetching: boolean;
	hasNextPage: boolean;
	isFetchingNextPage: boolean;
	onRetry: () => void;
	onLoadMore: () => void;
}) {
	const online = useOnline();
	const deleteMutation = useDeleteComment(groupId, transactionId);

	if (isPending) {
		return <div aria-busy="true" className="h-24 rounded-[28px] bg-sunken" />;
	}
	if (isError && comments.length === 0) {
		return <LoadError onRetry={onRetry} isRetrying={isFetching} />;
	}
	if (comments.length === 0) {
		return (
			<p className="py-6 text-center text-sm text-muted">
				{vi.transactionView.noComments}
			</p>
		);
	}

	return (
		<section className="grid gap-3">
			{comments.map((comment) => {
				const canDelete = verified && (comment.mine || role === "owner");
				return (
					<article
						key={comment.id}
						className="grid gap-1.5 rounded-[24px] bg-surface px-4 py-3"
					>
						<div className="flex items-baseline justify-between gap-2">
							<span className="text-xs font-extrabold">
								{comment.authorName}
							</span>
							<span className="text-[11px] text-muted">
								{formatVietnamDateTime(new Date(comment.createdAt))}
							</span>
						</div>
						<p className="whitespace-pre-wrap break-words text-sm">
							{comment.body}
						</p>
						{canDelete && (
							<div>
								<button
									type="button"
									disabled={!online || deleteMutation.isPending}
									onClick={() => deleteMutation.mutate(comment.id)}
									className="min-h-11 text-xs font-bold text-muted underline-offset-2 hover:underline disabled:opacity-50"
								>
									{vi.transactionView.deleteComment}
								</button>
							</div>
						)}
					</article>
				);
			})}
			{hasNextPage && (
				<Button
					variant="surface"
					disabled={isFetchingNextPage}
					onClick={onLoadMore}
				>
					{vi.transactionView.loadMoreComments}
				</Button>
			)}
			{deleteMutation.isError && (
				<p role="alert" className="text-xs font-bold">
					{vi.common.saveError}
				</p>
			)}
		</section>
	);
}
