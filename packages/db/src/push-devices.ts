import { and, count, eq, gt } from "drizzle-orm";
import { lockAccount } from "./accounts.js";
import type { DbExecutor } from "./client.js";
import { sessions, users } from "./schema.js";
import { pushDevices } from "./schema-push.js";

export type DbPushPlatform = "ios" | "android";
export type DbPushEnvironment = "sandbox" | "production";

export type ActivePushDevice = {
	id: string;
	userId: string;
	sessionId: string;
	platform: DbPushPlatform;
	token: string;
	environment: DbPushEnvironment;
	lastSeenAt: Date;
};

const MAX_ACTIVE_DEVICES_PER_USER = 10;

export async function upsertPushDevice(
	executor: DbExecutor,
	input: {
		userId: string;
		sessionId: string;
		platform: DbPushPlatform;
		token: string;
		environment: DbPushEnvironment;
		now: Date;
	},
): Promise<{ status: "ok"; id: string } | { status: "limit_reached" }> {
	await lockAccount(executor, input.userId);
	const [existing] = await executor
		.select({ id: pushDevices.id, userId: pushDevices.userId })
		.from(pushDevices)
		.where(eq(pushDevices.token, input.token))
		.limit(1);

	if (!existing || existing.userId !== input.userId) {
		const [active] = await executor
			.select({ total: count() })
			.from(pushDevices)
			.innerJoin(sessions, eq(pushDevices.sessionId, sessions.id))
			.where(
				and(
					eq(pushDevices.userId, input.userId),
					gt(sessions.expiresAt, input.now),
				),
			);
		if (Number(active?.total ?? 0) >= MAX_ACTIVE_DEVICES_PER_USER) {
			return { status: "limit_reached" };
		}
	}

	const [upserted] = await executor
		.insert(pushDevices)
		.values({
			userId: input.userId,
			sessionId: input.sessionId,
			platform: input.platform,
			token: input.token,
			environment: input.environment,
			createdAt: input.now,
			lastSeenAt: input.now,
		})
		.onConflictDoUpdate({
			target: pushDevices.token,
			set: {
				userId: input.userId,
				sessionId: input.sessionId,
				platform: input.platform,
				environment: input.environment,
				lastSeenAt: input.now,
			},
		})
		.returning({ id: pushDevices.id });

	if (!upserted) {
		throw new Error("Push device upsert failed");
	}
	return { status: "ok", id: upserted.id };
}

export async function deletePushDeviceForUser(
	executor: DbExecutor,
	input: { id: string; userId: string },
): Promise<boolean> {
	const deleted = await executor
		.delete(pushDevices)
		.where(
			and(eq(pushDevices.id, input.id), eq(pushDevices.userId, input.userId)),
		)
		.returning({ id: pushDevices.id });
	return deleted.length > 0;
}

export async function listActivePushDevicesForUser(
	executor: DbExecutor,
	input: { userId: string; now: Date },
): Promise<ActivePushDevice[]> {
	const rows = await executor
		.select({
			id: pushDevices.id,
			userId: pushDevices.userId,
			sessionId: pushDevices.sessionId,
			platform: pushDevices.platform,
			token: pushDevices.token,
			environment: pushDevices.environment,
			lastSeenAt: pushDevices.lastSeenAt,
		})
		.from(pushDevices)
		.innerJoin(sessions, eq(pushDevices.sessionId, sessions.id))
		.where(
			and(
				eq(pushDevices.userId, input.userId),
				gt(sessions.expiresAt, input.now),
			),
		);
	return rows as ActivePushDevice[];
}

export async function deletePushDeviceIfUnchanged(
	executor: DbExecutor,
	input: {
		id: string;
		userId: string;
		sessionId: string;
		token: string;
		lastSeenAt: Date;
	},
): Promise<boolean> {
	const deleted = await executor
		.delete(pushDevices)
		.where(
			and(
				eq(pushDevices.id, input.id),
				eq(pushDevices.userId, input.userId),
				eq(pushDevices.sessionId, input.sessionId),
				eq(pushDevices.token, input.token),
				eq(pushDevices.lastSeenAt, input.lastSeenAt),
			),
		)
		.returning({ id: pushDevices.id });
	return deleted.length > 0;
}

export async function updateUserHidePushContent(
	executor: DbExecutor,
	input: { userId: string; hideContent: boolean; now: Date },
): Promise<boolean> {
	const updated = await executor
		.update(users)
		.set({
			hidePushContent: input.hideContent,
			updatedAt: input.now,
		})
		.where(eq(users.id, input.userId))
		.returning({ id: users.id });
	return updated.length > 0;
}
