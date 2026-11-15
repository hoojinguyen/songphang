import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	GroupResponse,
	GroupUsersResponse,
	TransferOwnershipRequest,
	UpdateGroupUserRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import {
	changeGroupUser,
	getGroupUsers,
	leaveGroup,
	removeGroupUser,
	transferOwnership,
} from "../services/group-users.js";

const params = z.object({ groupId: z.uuid() });
const userParams = params.extend({ userId: z.uuid() });
const list = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/users",
	request: { params },
	responses: {
		200: {
			description: "Group users",
			content: { "application/json": { schema: GroupUsersResponse } },
		},
	},
});
const change = createRoute({
	method: "patch",
	path: "/api/v1/groups/{groupId}/users/{userId}",
	request: {
		params: userParams,
		body: {
			required: true,
			content: { "application/json": { schema: UpdateGroupUserRequest } },
		},
	},
	responses: {
		200: {
			description: "Role changed",
			content: { "application/json": { schema: GroupUsersResponse } },
		},
	},
});
const remove = createRoute({
	method: "delete",
	path: "/api/v1/groups/{groupId}/users/{userId}",
	request: { params: userParams },
	responses: { 204: { description: "User removed" } },
});
const transfer = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/transfer-ownership",
	request: {
		params,
		body: {
			required: true,
			content: { "application/json": { schema: TransferOwnershipRequest } },
		},
	},
	responses: {
		200: {
			description: "Ownership transferred",
			content: { "application/json": { schema: GroupResponse } },
		},
	},
});
const leave = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/leave",
	request: { params },
	responses: { 204: { description: "Left group" } },
});
export function registerGroupUserRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
) {
	const signedIn = requireUser(deps);
	const writes = [
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	const owner = [signedIn, requireGroupRole(deps, "owner"), ...writes];
	app.openapi(
		{ ...list, middleware: [signedIn, requireGroupRole(deps, "viewer")] },
		async (c) =>
			c.json(
				await getGroupUsers(deps, {
					groupId: c.var.groupAccess.groupId,
					userId: c.var.user.id,
				}),
				200,
			),
	);
	app.openapi({ ...change, middleware: owner }, async (c) =>
		c.json(
			await changeGroupUser(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
				targetId: c.req.valid("param").userId,
				request: c.req.valid("json"),
			}),
			200,
		),
	);
	app.openapi({ ...remove, middleware: owner }, async (c) => {
		await removeGroupUser(deps, {
			groupId: c.var.groupAccess.groupId,
			userId: c.var.user.id,
			targetId: c.req.valid("param").userId,
		});
		return c.body(null, 204);
	});
	app.openapi({ ...transfer, middleware: owner }, async (c) =>
		c.json(
			await transferOwnership(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
				targetId: c.req.valid("json").userId,
			}),
			200,
		),
	);
	app.openapi(
		{
			...leave,
			middleware: [signedIn, requireGroupRole(deps, "viewer"), ...writes],
		},
		async (c) => {
			await leaveGroup(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
			});
			return c.body(null, 204);
		},
	);
}
