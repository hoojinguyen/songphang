import { findGroupAccess } from "@songphang/db";
import type { AppDeps } from "../app.js";
import { findSessionUser } from "./sessions.js";
export async function hasGroupSession(
	deps: AppDeps,
	input: { groupId: string; token: string },
) {
	const user = await findSessionUser(deps.db, input.token, deps.now());
	return (
		user !== null &&
		(await findGroupAccess(deps.db, input.groupId, user.id)) !== null
	);
}
