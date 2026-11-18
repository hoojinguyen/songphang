import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ChatIdentitiesResponse,
	ChatLinksResponse,
	ChatPlatform,
	ClaimChatIdentityRequest,
	CreateChatLinkCodeResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import {
	claimUserChatIdentity,
	createGroupChatLinkCode,
	getGroupChatLinks,
	getUserChatIdentities,
	unlinkGroupChat,
	unlinkUserChatIdentity,
} from "../services/chat-links.js";

export function registerChatLinkRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/chat-links/code",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "owner"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: { params: z.object({ groupId: z.uuid() }) },
			responses: {
				200: {
					description: "Generated one-time chat link command",
					content: {
						"application/json": { schema: CreateChatLinkCodeResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await createGroupChatLinkCode(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
				}),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/chat-links",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "owner"),
				requireVerifiedEmail(deps),
			],
			request: { params: z.object({ groupId: z.uuid() }) },
			responses: {
				200: {
					description: "Linked chats for this group",
					content: { "application/json": { schema: ChatLinksResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await getGroupChatLinks(deps, context.var.groupAccess.groupId),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/chat-links/{chatLinkId}",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "owner"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: z.object({ groupId: z.uuid(), chatLinkId: z.uuid() }),
			},
			responses: {
				204: { description: "Chat unlinked" },
			},
		}),
		async (context) => {
			await unlinkGroupChat(deps, {
				groupId: context.var.groupAccess.groupId,
				chatLinkId: context.req.valid("param").chatLinkId,
			});
			return context.body(null, 204);
		},
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me/chat-identities",
			middleware: [requireUser(deps)],
			responses: {
				200: {
					description: "Linked chat identities for current user",
					content: { "application/json": { schema: ChatIdentitiesResponse } },
				},
			},
		}),
		async (context) =>
			context.json(await getUserChatIdentities(deps, context.var.user.id), 200),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/me/chat-identities/claim",
			middleware: [
				requireUser(deps),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				body: {
					required: true,
					content: { "application/json": { schema: ClaimChatIdentityRequest } },
				},
			},
			responses: {
				204: { description: "Chat identity linked" },
			},
		}),
		async (context) => {
			await claimUserChatIdentity(deps, {
				userId: context.var.user.id,
				code: context.req.valid("json").code,
			});
			return context.body(null, 204);
		},
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/me/chat-identities/{platform}",
			middleware: [
				requireUser(deps),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: { params: z.object({ platform: ChatPlatform }) },
			responses: {
				204: { description: "Chat identity unlinked" },
			},
		}),
		async (context) => {
			await unlinkUserChatIdentity(deps, {
				userId: context.var.user.id,
				platform: context.req.valid("param").platform,
			});
			return context.body(null, 204);
		},
	);
}
