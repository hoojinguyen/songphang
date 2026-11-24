import { type DbExecutor, lockGroup } from "@songphang/db";
import { AppError } from "../errors.js";

/** Throws 404 if the group row is missing or 409 GROUP_ARCHIVED when archived. */
export function assertGroupRowNotArchived(
	group: { archivedAt: Date | null } | null,
): void {
	if (group === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	if (group.archivedAt !== null) {
		throw new AppError(409, "GROUP_ARCHIVED", "Group is archived");
	}
}

/** Locks the group row FOR UPDATE and enforces that it is not archived. */
export async function assertGroupNotArchived(
	executor: DbExecutor,
	groupId: string,
): Promise<{ id: string; archivedAt: Date | null }> {
	const group = await lockGroup(executor, groupId);
	assertGroupRowNotArchived(group);
	if (group === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	return group;
}
