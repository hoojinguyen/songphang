import { asc, eq } from "drizzle-orm";
import type { Db } from "./client.js";
import { users } from "./schema.js";

export const USER_COLUMNS = {
	id: users.id,
	email: users.email,
	name: users.name,
	avatarUrl: users.avatarUrl,
};

export function listUsers(db: Db) {
	return db
		.select(USER_COLUMNS)
		.from(users)
		.orderBy(asc(users.createdAt), asc(users.id));
}

export async function findUserById(db: Db, userId: string) {
	const [user] = await db
		.select(USER_COLUMNS)
		.from(users)
		.where(eq(users.id, userId))
		.limit(1);
	return user ?? null;
}
