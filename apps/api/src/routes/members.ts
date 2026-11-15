import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateMemberRequest,
	IdempotencyKeyHeader,
	MemberResponse,
	MembersResponse,
	UpdateMemberRequest,
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
	createMember,
	editMember,
	listMembers,
	removeMember,
} from "../services/members.js";

const params = z.object({ groupId: z.uuid() });
const memberParams = params.extend({ memberId: z.string() });
const listRoute = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/members",
	request: { params },
	responses: {
		200: {
			description: "Members",
			content: { "application/json": { schema: MembersResponse } },
		},
	},
});
const createMemberRoute = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/members",
	request: {
		params,
		headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
		body: {
			required: true,
			content: { "application/json": { schema: CreateMemberRequest } },
		},
	},
	responses: {
		201: {
			description: "Member created",
			content: { "application/json": { schema: MemberResponse } },
		},
	},
});
const editRoute = createRoute({
	method: "patch",
	path: "/api/v1/groups/{groupId}/members/{memberId}",
	request: {
		params: memberParams,
		body: {
			required: true,
			content: { "application/json": { schema: UpdateMemberRequest } },
		},
	},
	responses: {
		200: {
			description: "Member updated",
			content: { "application/json": { schema: MemberResponse } },
		},
	},
});
const deleteRoute = createRoute({
	method: "delete",
	path: "/api/v1/groups/{groupId}/members/{memberId}",
	request: { params: memberParams },
	responses: { 204: { description: "Member deleted" } },
});
export function registerMemberRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const write = [
		requireUser(deps),
		requireGroupRole(deps, "editor"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	app.openapi({ ...listRoute, middleware: read }, async (context) =>
		context.json(
			await listMembers(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				myMemberId: context.var.groupAccess.memberId,
			}),
			200,
		),
	);
	app.openapi({ ...createMemberRoute, middleware: write }, async (context) => {
		const request = context.req.valid("json");
		const response = await runIdempotent(
			deps,
			{
				userId: context.var.user.id,
				key: context.req.valid("header")["idempotency-key"],
				onCommitted: () =>
					deps.events.publishChanged(context.var.groupAccess.groupId, [
						"members",
						"balances",
						"activity",
					]),
				requestHash: hashRequest("POST", context.req.path, request),
			},
			async (transaction) => ({
				status: 201,
				body: await createMember(transaction, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					myMemberId: context.var.groupAccess.memberId,
					request,
					now: deps.now(),
				}),
			}),
		);
		return context.json(MemberResponse.parse(response.body), 201);
	});
	app.openapi({ ...editRoute, middleware: write }, async (context) =>
		context.json(
			await editMember(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				myMemberId: context.var.groupAccess.memberId,
				memberId: context.req.valid("param").memberId,
				request: context.req.valid("json"),
			}),
			200,
		),
	);
	app.openapi({ ...deleteRoute, middleware: write }, async (context) => {
		await removeMember(deps, {
			groupId: context.var.groupAccess.groupId,
			userId: context.var.user.id,
			myMemberId: context.var.groupAccess.memberId,
			memberId: context.req.valid("param").memberId,
		});
		return context.body(null, 204);
	});
}
