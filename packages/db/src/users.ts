import { asc, eq, sql } from "drizzle-orm";
import type { Db, DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { userIdentities } from "./schema-accounts.js";

export const USER_COLUMNS = {
	id: users.id,
	email: users.email,
	name: users.name,
	avatarUrl: users.avatarUrl,
	hidePushContent: users.hidePushContent,
	emailVerified: sql<boolean>`${users.emailVerifiedAt} is not null`,
	hasPassword: sql<boolean>`exists(select 1 from ${userIdentities} where ${userIdentities}."user_id" = ${users}."id" and ${userIdentities}."provider" = 'password')`,
};

export function listUsers(db: Db) {
	return db
		.select(USER_COLUMNS)
		.from(users)
		.orderBy(asc(users.createdAt), asc(users.id));
}

export async function findUserById(db: DbExecutor, userId: string) {
	const [user] = await db
		.select(USER_COLUMNS)
		.from(users)
		.where(eq(users.id, userId))
		.limit(1);
	return user ?? null;
}
