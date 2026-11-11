import { createHash, randomBytes } from "node:crypto";
import { z } from "@hono/zod-openapi";
import { UserDto } from "@songphang/contract";
import {
	type Db,
	deleteSessionByHash,
	findUserById,
	findUserBySessionHash,
	insertSession,
} from "@songphang/db";
import type { Config } from "../config.js";
import { AppError } from "../errors.js";

export const SESSION_COOKIE = "sp_session";
export const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000;

const SESSION_TOKEN_SCHEMA = z
	.string()
	.length(43)
	.regex(/^[A-Za-z0-9_-]+$/);

function hashToken(token: string): string {
	return createHash("sha256").update(token).digest("hex");
}

export async function createSession(
	db: Db,
	input: {
		userId: string;
		now: Date;
		userAgent?: string;
	},
): Promise<{ token: string; expiresAt: Date }> {
	if ((await findUserById(db, input.userId)) === null) {
		throw new AppError(404, "NOT_FOUND", "User not found");
	}
	const token = randomBytes(32).toString("base64url");
	const expiresAt = new Date(input.now.getTime() + SESSION_TTL_MS);
	await insertSession(db, { ...input, tokenHash: hashToken(token), expiresAt });
	return { token, expiresAt };
}

export async function findSessionUser(
	db: Db,
	token: string,
	now: Date,
): Promise<UserDto | null> {
	if (!SESSION_TOKEN_SCHEMA.safeParse(token).success) return null;
	const user = await findUserBySessionHash(db, {
		tokenHash: hashToken(token),
		now,
	});
	return user === null ? null : UserDto.parse(user);
}

export async function deleteSession(db: Db, token: string): Promise<void> {
	if (!SESSION_TOKEN_SCHEMA.safeParse(token).success) return;
	await deleteSessionByHash(db, hashToken(token));
}

export function sessionCookieAttributes(appEnv: Config["appEnv"]) {
	return {
		httpOnly: true,
		sameSite: "Lax",
		path: "/",
		secure: appEnv === "production",
		maxAge: SESSION_TTL_MS / 1000,
	} as const;
}
