import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ChooseMemberRequest,
	GroupResponse,
	IdempotencyKeyHeader,
	InvitePreviewResponse,
	InviteResponse,
	InviteToken,
	JoinRequest,
	JoinResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { socketIp } from "../auth/account-limits.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import {
	changeInvite,
	chooseMember,
	getInvite,
	joinInvite,
	previewInvite,
} from "../services/invites.js";

const params = z.object({ groupId: z.uuid() });
const tokenParams = z.object({ token: InviteToken });
const preview = createRoute({
	method: "get",
	path: "/api/v1/invites/{token}",
	request: { params: tokenParams },
	responses: {
		200: {
			description: "Invite preview",
			content: { "application/json": { schema: InvitePreviewResponse } },
		},
	},
});
const join = createRoute({
	method: "post",
	path: "/api/v1/invites/{token}/join",
	request: {
		params: tokenParams,
		headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
		body: {
			required: true,
			content: { "application/json": { schema: JoinRequest } },
		},
	},
	responses: {
		200: {
			description: "Joined",
			content: { "application/json": { schema: JoinResponse } },
		},
	},
});
const read = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/invite",
	request: { params },
	responses: {
		200: {
			description: "Invite",
			content: { "application/json": { schema: InviteResponse } },
		},
	},
});
const toggle = createRoute({
	method: "patch",
	path: "/api/v1/groups/{groupId}/invite",
	request: {
		params,
		body: {
			required: true,
			content: {
				"application/json": { schema: z.object({ active: z.boolean() }) },
			},
		},
	},
	responses: {
		200: {
			description: "Invite changed",
			content: { "application/json": { schema: InviteResponse } },
		},
	},
});
const rotate = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/invite/rotate",
	request: { params },
	responses: {
		200: {
			description: "Invite rotated",
			content: { "application/json": { schema: InviteResponse } },
		},
	},
});
const choose = createRoute({
	method: "put",
	path: "/api/v1/groups/{groupId}/me/member",
	request: {
		params,
		body: {
			required: true,
			content: { "application/json": { schema: ChooseMemberRequest } },
		},
	},
	responses: {
		200: {
			description: "Member chosen",
			content: { "application/json": { schema: GroupResponse } },
		},
	},
});
export function registerInviteRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
	const signedIn = requireUser(deps);
	const write = [
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	const owner = [signedIn, requireGroupRole(deps, "owner"), ...write];
	app.openapi(
		{
			...preview,
			middleware: [
				signedIn,
				deps.rateLimiter.limit({
					name: "invite-preview",
					max: 30,
					windowMs: 60_000,
					key: socketIp,
				}),
			],
		},
		async (c) =>
			c.json(
				await previewInvite(deps, {
					token: c.req.valid("param").token,
					userId: c.var.user.id,
				}),
				200,
			),
	);
	app.openapi({ ...join, middleware: [signedIn, ...write] }, async (c) => {
		const request = c.req.valid("json");
		const response = await runIdempotent(
			deps,
			{
				userId: c.var.user.id,
				key: c.req.valid("header")["idempotency-key"],
				requestHash: hashRequest("POST", c.req.path, request),
			},
			async (tx) => ({
				status: 200,
				body: await joinInvite(tx, {
					token: c.req.valid("param").token,
					userId: c.var.user.id,
					request,
					now: deps.now(),
				}),
			}),
		);
		return c.json(JoinResponse.parse(response.body), 200);
	});
	app.openapi(
		{ ...read, middleware: [signedIn, requireGroupRole(deps, "editor")] },
		async (c) => c.json(await getInvite(deps, c.var.groupAccess.groupId), 200),
	);
	app.openapi({ ...toggle, middleware: owner }, async (c) =>
		c.json(
			await changeInvite(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
				active: c.req.valid("json").active,
			}),
			200,
		),
	);
	app.openapi({ ...rotate, middleware: owner }, async (c) =>
		c.json(
			await changeInvite(deps, {
				groupId: c.var.groupAccess.groupId,
				userId: c.var.user.id,
				rotate: true,
			}),
			200,
		),
	);
	app.openapi(
		{
			...choose,
			middleware: [signedIn, requireGroupRole(deps, "viewer"), ...write],
		},
		async (c) =>
			c.json(
				await chooseMember(deps, {
					groupId: c.var.groupAccess.groupId,
					userId: c.var.user.id,
					memberId: c.req.valid("json").memberId,
				}),
				200,
			),
	);
}
