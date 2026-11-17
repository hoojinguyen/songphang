import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	MemberResponse,
	ReplacePaymentMethodsRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { setPaymentMethods } from "../services/payment-methods.js";
export function registerPaymentMethodRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
) {
	app.openapi(
		createRoute({
			method: "put",
			path: "/api/v1/groups/{groupId}/members/{memberId}/payment-methods",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "viewer"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: z.object({ groupId: z.uuid(), memberId: z.uuid() }),
				body: {
					required: true,
					content: {
						"application/json": { schema: ReplacePaymentMethodsRequest },
					},
				},
			},
			responses: {
				200: {
					description: "Member payment methods replaced",
					content: { "application/json": { schema: MemberResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await setPaymentMethods(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					memberId: context.req.valid("param").memberId,
					methods: context.req.valid("json").methods,
				}),
				200,
			),
	);
}
