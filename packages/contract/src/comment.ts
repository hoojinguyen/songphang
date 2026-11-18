import { z } from "@hono/zod-openapi";

export const CommentDto = z
	.object({
		id: z.uuid(),
		authorUserId: z.uuid().nullable(),
		authorName: z.string(),
		body: z.string(),
		createdAt: z.iso.datetime(),
		mine: z.boolean(),
	})
	.openapi("CommentDto");
export type CommentDto = z.infer<typeof CommentDto>;

export const CommentResponse = z
	.object({ comment: CommentDto })
	.openapi("CommentResponse");
export type CommentResponse = z.infer<typeof CommentResponse>;

export const CommentsQuery = z.object({
	cursor: z.string().max(512).optional(),
	limit: z.coerce.number().int().min(1).max(200).default(50),
});
export type CommentsQuery = z.infer<typeof CommentsQuery>;

export const CommentsResponse = z
	.object({
		comments: z.array(CommentDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("CommentsResponse");
export type CommentsResponse = z.infer<typeof CommentsResponse>;

export const CreateCommentRequest = z
	.object({
		body: z.string().trim().min(1).max(1000),
	})
	.openapi("CreateCommentRequest");
export type CreateCommentRequest = z.infer<typeof CreateCommentRequest>;
