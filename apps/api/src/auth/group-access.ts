import { z } from "@hono/zod-openapi";
import { GroupRole } from "@songphang/contract";
import { findGroupAccess } from "@songphang/db";
import { createMiddleware } from "hono/factory";
import type { AppDeps, AppEnv } from "../app.js";
import { AppError } from "../errors.js";

const ROLE_RANK = { viewer: 0, editor: 1, owner: 2 };
export function requireGroupRole(deps: AppDeps, minimumRole: GroupRole) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const groupId = z.uuid().safeParse(context.req.param("groupId"));
		if (!groupId.success)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const access = await findGroupAccess(
			deps.db,
			groupId.data,
			context.var.user.id,
		);
		if (access === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const role = GroupRole.parse(access.role);
		if (ROLE_RANK[role] < ROLE_RANK[minimumRole])
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		context.set("groupAccess", { ...access, role });
		await next();
	});
}
