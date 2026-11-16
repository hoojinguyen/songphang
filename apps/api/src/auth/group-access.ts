import { z } from "@hono/zod-openapi";
import { GroupRole } from "@songphang/contract";
import { type DbExecutor, findGroupAccess } from "@songphang/db";
import { createMiddleware } from "hono/factory";
import type { AppDeps, AppEnv } from "../app.js";
import { AppError } from "../errors.js";

const ROLE_RANK = { viewer: 0, editor: 1, owner: 2 };
export function requireGroupRole(deps: AppDeps, minimumRole: GroupRole) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const groupId = z.uuid().safeParse(context.req.param("groupId"));
		if (!groupId.success)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const access = await getGroupAccess(deps.db, {
			groupId: groupId.data,
			userId: context.var.user.id,
			minimumRole,
		});
		const role = access.role;
		context.set("groupAccess", { ...access, role });
		await next();
	});
}

export async function getGroupAccess(
	executor: DbExecutor,
	input: { groupId: string; userId: string; minimumRole: GroupRole },
) {
	const access = await findGroupAccess(executor, input.groupId, input.userId);
	if (access === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const role = GroupRole.parse(access.role);
	if (ROLE_RANK[role] < ROLE_RANK[input.minimumRole])
		throw new AppError(403, "FORBIDDEN", "Insufficient group role");
	return { ...access, role };
}
