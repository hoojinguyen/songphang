import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CategoriesResponse,
	CategoryResponse,
	CreateCategoryRequest,
	IdempotencyKeyHeader,
	UpdateCategoryRequest,
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
	archiveCategory,
	createCategory,
	listCategories,
	updateCategory,
} from "../services/categories.js";

const params = z.object({ groupId: z.uuid() });
const itemParams = params.extend({ id: z.string().max(100) });
const path = "/api/v1/groups/{groupId}/categories";

export function registerCategoryRoutes(
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
	app.openapi(
		createRoute({
			method: "get",
			path,
			middleware: read,
			request: { params },
			responses: {
				200: {
					description: "Group categories",
					content: { "application/json": { schema: CategoriesResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await listCategories(deps, context.var.groupAccess.groupId),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "post",
			path,
			middleware: write,
			request: {
				params,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CreateCategoryRequest } },
				},
			},
			responses: {
				201: {
					description: "Category created",
					content: { "application/json": { schema: CategoryResponse } },
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
					requestHash: hashRequest("POST", context.req.path, request),
					onCommitted: () =>
						deps.events.publishChanged(context.var.groupAccess.groupId, [
							"categories",
						]),
				},
				async (executor) => ({
					status: 201,
					body: await createCategory(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(CategoryResponse.parse(response.body), 201);
		},
	);
	app.openapi(
		createRoute({
			method: "patch",
			path: `${path}/{id}`,
			middleware: write,
			request: {
				params: itemParams,
				body: {
					required: true,
					content: { "application/json": { schema: UpdateCategoryRequest } },
				},
			},
			responses: {
				200: {
					description: "Category updated",
					content: { "application/json": { schema: CategoryResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await updateCategory(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					id: context.req.valid("param").id,
					request: context.req.valid("json"),
				}),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "delete",
			path: `${path}/{id}`,
			middleware: write,
			request: { params: itemParams },
			responses: { 204: { description: "Category archived" } },
		}),
		async (context) => {
			await archiveCategory(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				id: context.req.valid("param").id,
			});
			return context.body(null, 204);
		},
	);
}
