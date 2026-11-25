import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CloneGroupRequest,
	CreateGroupRequest,
	DeleteGroupRequest,
	GroupMuteResponse,
	GroupResponse,
	GroupsQuery,
	GroupsResponse,
	IdempotencyKeyHeader,
	UpdateGroupMuteRequest,
	UpdateGroupRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import {
	cloneGroup,
	createGroup,
	deleteGroup,
	editGroup,
	getGroup,
	listGroups,
	setGroupArchived,
} from "../services/groups.js";
import { setGroupMuted } from "../services/notifications.js";

const groupParams = z.object({ groupId: z.uuid() });
const listRoute = createRoute({
	method: "get",
	path: "/api/v1/groups",
	request: { query: GroupsQuery },
	responses: {
		200: {
			description: "Groups",
			content: { "application/json": { schema: GroupsResponse } },
		},
	},
});
const createGroupRoute = createRoute({
	method: "post",
	path: "/api/v1/groups",
	request: {
		headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
		body: {
			required: true,
			content: { "application/json": { schema: CreateGroupRequest } },
		},
	},
	responses: {
		201: {
			description: "Group created",
			content: { "application/json": { schema: GroupResponse } },
		},
	},
});
const getRoute = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}",
	request: { params: groupParams },
	responses: {
		200: {
			description: "Group",
			content: { "application/json": { schema: GroupResponse } },
		},
	},
});
const editRoute = createRoute({
	method: "patch",
	path: "/api/v1/groups/{groupId}",
	request: {
		params: groupParams,
		body: {
			required: true,
			content: { "application/json": { schema: UpdateGroupRequest } },
		},
	},
	responses: {
		200: {
			description: "Group updated",
			content: { "application/json": { schema: GroupResponse } },
		},
	},
});

export function registerGroupRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "owner"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: groupParams,
				body: {
					required: true,
					content: { "application/json": { schema: DeleteGroupRequest } },
				},
			},
			responses: { 204: { description: "Group deleted" } },
		}),
		async (c) => {
			await deleteGroup(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
				request: c.req.valid("json"),
			});
			return c.body(null, 204);
		},
	);
	app.openapi(
		{ ...listRoute, middleware: [requireUser(deps)] },
		async (context) =>
			context.json(
				await listGroups(
					deps,
					context.var.user.id,
					context.req.valid("query").status,
				),
				200,
			),
	);
	app.openapi(
		{
			...createGroupRoute,
			middleware: [
				requireUser(deps),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
		},
		async (context) => {
			const request = context.req.valid("json");
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					onCommitted: (body) =>
						deps.events.publishChanged(GroupResponse.parse(body).group.id, [
							"group",
							"members",
							"users",
							"activity",
						]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (transaction) => ({
					status: 201,
					body: await createGroup(transaction, {
						request,
						user: context.var.user,
						now: deps.now(),
					}),
				}),
			);
			return context.json(GroupResponse.parse(response.body), 201);
		},
	);
	app.openapi(
		{
			...getRoute,
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
		},
		async (context) =>
			context.json(
				await getGroup(
					deps.db,
					context.var.groupAccess.groupId,
					context.var.user.id,
				),
				200,
			),
	);
	app.openapi(
		{
			...editRoute,
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "owner"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
		},
		async (context) =>
			context.json(
				await editGroup(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					changes: context.req.valid("json"),
				}),
				200,
			),
	);
	for (const action of ["archive", "unarchive"] as const) {
		app.openapi(
			createRoute({
				method: "post",
				path: `/api/v1/groups/{groupId}/${action}`,
				middleware: [
					requireUser(deps),
					requireGroupRole(deps, "owner"),
					requireVerifiedEmail(deps),
					requireWriteLimit(deps),
					requireSameOrigin(deps.config),
				],
				request: { params: groupParams },
				responses: {
					200: {
						description:
							action === "archive" ? "Group archived" : "Group unarchived",
						content: { "application/json": { schema: GroupResponse } },
					},
				},
			}),
			async (context) =>
				context.json(
					await setGroupArchived(deps, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						archived: action === "archive",
					}),
					200,
				),
		);
	}
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/clone",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "editor"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: groupParams,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CloneGroupRequest } },
				},
			},
			responses: {
				201: {
					description: "Group cloned",
					content: { "application/json": { schema: GroupResponse } },
				},
			},
		}),
		async (context) => {
			const request = context.req.valid("json");
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					onCommitted: (body) =>
						deps.events.publishChanged(GroupResponse.parse(body).group.id, [
							"group",
							"members",
							"users",
							"activity",
						]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (transaction) => ({
					status: 201,
					body: await cloneGroup(transaction, {
						sourceGroupId: context.var.groupAccess.groupId,
						request,
						user: context.var.user,
						now: deps.now(),
					}),
				}),
			);
			return context.json(GroupResponse.parse(response.body), 201);
		},
	);
	app.openapi(
		createRoute({
			method: "put",
			path: "/api/v1/groups/{groupId}/me/muted",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "viewer"),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: groupParams,
				body: {
					required: true,
					content: { "application/json": { schema: UpdateGroupMuteRequest } },
				},
			},
			responses: {
				200: {
					description: "Group mute updated",
					content: { "application/json": { schema: GroupMuteResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await setGroupMuted(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					muted: context.req.valid("json").muted,
				}),
				200,
			),
	);
}
