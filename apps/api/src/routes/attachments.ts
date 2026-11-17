import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { AttachmentResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { AppError } from "../errors.js";
import { requireUploadLimit } from "../rate-limit.js";
import {
	deleteAttachment,
	getAttachmentContent,
	uploadAttachment,
} from "../services/attachments.js";
import { sniffImageType } from "../storage/sniff.js";
import {
	readSingleUploadedFile,
	streamingUploadLimit,
} from "./attachment-body.js";

const params = z.object({ groupId: z.uuid() });
const itemParams = params.extend({ id: z.string().max(100) });

export function registerAttachmentRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/attachments",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "editor"),
				requireVerifiedEmail(deps),
				requireSameOrigin(deps.config),
				requireWriteLimit(deps),
				requireUploadLimit(deps),
				streamingUploadLimit(),
			],
			request: { params },
			responses: {
				201: {
					description: "Attachment uploaded",
					content: { "application/json": { schema: AttachmentResponse } },
				},
			},
		}),
		async (context) => {
			const bytes = await readSingleUploadedFile(context.req.raw);
			const contentType = sniffImageType(bytes);
			if (contentType === null) {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"File is not a supported image",
					{ reason: "not_an_image" },
				);
			}
			const result = await uploadAttachment(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				bytes,
				contentType,
			});
			return context.json(result, 201);
		},
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/attachments/{id}/content",
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
			request: { params: itemParams },
			responses: {
				200: {
					description: "Attachment binary content",
					content: { "image/jpeg": { schema: z.string() } },
				},
			},
		}),
		async (context) => {
			const { bytes, contentType } = await getAttachmentContent(deps, {
				groupId: context.var.groupAccess.groupId,
				id: context.req.valid("param").id,
				userId: context.var.user.id,
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

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/attachments/{id}",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "editor"),
				requireVerifiedEmail(deps),
				requireSameOrigin(deps.config),
				requireWriteLimit(deps),
			],
			request: { params: itemParams },
			responses: {
				204: { description: "Attachment deleted" },
			},
		}),
		async (context) => {
			await deleteAttachment(deps, {
				groupId: context.var.groupAccess.groupId,
				id: context.req.valid("param").id,
				userId: context.var.user.id,
			});
			return context.body(null, 204);
		},
	);
}
