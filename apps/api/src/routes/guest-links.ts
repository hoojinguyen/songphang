import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateGuestLinkRequest,
	GuestGroupViewQuery,
	GuestGroupViewResponse,
	GuestLinkResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { socketIp } from "../auth/account-limits.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { AppError } from "../errors.js";
import {
	enableOrRotateGuestLink,
	getGuestAttachmentContent,
	getGuestGroupView,
	getGuestLink,
	revokeGuestLink,
} from "../services/guest-links.js";

const groupParams = z.object({ groupId: z.uuid() });
const tokenParams = z.object({ token: z.string().max(128) });
const attachmentParams = tokenParams.extend({
	attachmentId: z.string().max(100),
});

async function parseOptionalGuestLinkBody(
	rawText: string,
): Promise<CreateGuestLinkRequest> {
	if (!rawText.trim()) return {};
	let json: unknown;
	try {
		json = JSON.parse(rawText);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid JSON body");
	}
	const parsed = CreateGuestLinkRequest.safeParse(json);
	if (!parsed.success) {
		throw new AppError(400, "VALIDATION_FAILED", "Validation failed");
	}
	return parsed.data;
}

export function registerGuestLinkRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const editorRead = [requireUser(deps), requireGroupRole(deps, "editor")];
	const editorWrite = [
		...editorRead,
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/guest-link",
			middleware: editorRead,
			request: { params: groupParams },
			responses: {
				200: {
					description: "Guest read-only link status",
					content: { "application/json": { schema: GuestLinkResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await getGuestLink(deps, context.var.groupAccess.groupId),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/guest-link",
			middleware: editorWrite,
			request: {
				params: groupParams,
				body: {
					required: false,
					content: {
						"application/json": { schema: CreateGuestLinkRequest },
					},
				},
			},
			responses: {
				200: {
					description: "Guest read-only link enabled or rotated",
					content: { "application/json": { schema: GuestLinkResponse } },
				},
			},
		}),
		async (context) => {
			const body = await parseOptionalGuestLinkBody(await context.req.text());
			return context.json(
				await enableOrRotateGuestLink(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					...(body.rotate === undefined ? {} : { rotate: body.rotate }),
				}),
				200,
			);
		},
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/guest-link",
			middleware: editorWrite,
			request: { params: groupParams },
			responses: {
				200: {
					description: "Guest read-only link revoked",
					content: { "application/json": { schema: GuestLinkResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await revokeGuestLink(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
				}),
				200,
			),
	);

	const noStoreMiddleware = async (
		context: Parameters<Parameters<typeof app.use>[1]>[0],
		next: Parameters<Parameters<typeof app.use>[1]>[1],
	) => {
		context.header("Cache-Control", "private, no-store");
		await next();
	};

	const publicViewRateLimit = deps.rateLimiter.limit({
		name: "guest_link_read",
		max: 60,
		windowMs: 60_000,
		key: socketIp,
	});
	const publicAttachmentRateLimit = deps.rateLimiter.limit({
		name: "guest_link_attachment",
		max: 120,
		windowMs: 60_000,
		key: socketIp,
	});

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/guest-links/{token}",
			middleware: [noStoreMiddleware, publicViewRateLimit],
			request: { params: tokenParams, query: GuestGroupViewQuery },
			responses: {
				200: {
					description: "Public read-only guest group view",
					content: { "application/json": { schema: GuestGroupViewResponse } },
				},
			},
		}),
		async (context) => {
			context.header("Cache-Control", "private, no-store");
			return context.json(
				await getGuestGroupView(deps, {
					token: context.req.valid("param").token,
					query: context.req.valid("query"),
				}),
				200,
			);
		},
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/guest-links/{token}/attachments/{attachmentId}",
			middleware: [noStoreMiddleware, publicAttachmentRateLimit],
			request: { params: attachmentParams },
			responses: {
				200: {
					description: "Expense or income receipt image for active guest link",
					content: {
						"image/jpeg": { schema: { type: "string", format: "binary" } },
						"image/png": { schema: { type: "string", format: "binary" } },
						"image/webp": { schema: { type: "string", format: "binary" } },
					},
				},
			},
		}),
		async (context) => {
			const { token, attachmentId } = context.req.valid("param");
			const { bytes, contentType } = await getGuestAttachmentContent(deps, {
				token,
				attachmentId,
			});
			return new Response(Buffer.from(bytes), {
				status: 200,
				headers: {
					"Content-Type": contentType,
					"X-Content-Type-Options": "nosniff",
					"Content-Disposition": 'inline; filename="hoa-don.jpg"',
					"Cache-Control": "private, no-store",
				},
			});
		},
	);
}
