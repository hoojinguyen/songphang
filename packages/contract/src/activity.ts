import { z } from "@hono/zod-openapi";
import { TransactionsQuery } from "./transaction.ts";
export const ActivityQuery = TransactionsQuery;
export type ActivityQuery = z.infer<typeof ActivityQuery>;
export const ActivityDto = z.object({
	id: z.uuid(),
	actor: z
		.object({
			userId: z.uuid(),
			name: z.string(),
			memberId: z.uuid().nullable(),
		})
		.nullable(),
	action: z.string(),
	entityType: z.enum(["transaction", "member", "group", "group_user"]),
	entityId: z.uuid().nullable(),
	summary: z.string(),
	before: z.record(z.string(), z.unknown()).nullable(),
	after: z.record(z.string(), z.unknown()).nullable(),
	createdAt: z.iso.datetime(),
	canRestore: z.boolean(),
});
export type ActivityDto = z.infer<typeof ActivityDto>;
export const ActivityResponse = z
	.object({ activity: z.array(ActivityDto), nextCursor: z.string().nullable() })
	.openapi("ActivityResponse");
