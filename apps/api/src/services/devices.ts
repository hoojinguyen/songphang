import type {
	RegisterDeviceRequest,
	RegisterDeviceResponse,
} from "@songphang/contract";
import {
	deletePushDeviceForUser,
	updateUserHidePushContent,
	upsertPushDevice,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";

export async function registerPushDevice(
	deps: AppDeps,
	input: {
		userId: string;
		sessionId: string;
		request: RegisterDeviceRequest;
	},
): Promise<RegisterDeviceResponse> {
	if (!deps.config.pushProvider) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const result = await deps.db.transaction(async (transaction) =>
		upsertPushDevice(transaction, {
			userId: input.userId,
			sessionId: input.sessionId,
			platform: input.request.platform,
			token: input.request.token,
			environment: input.request.environment,
			now: deps.now(),
		}),
	);
	if (result.status === "limit_reached") {
		throw new AppError(
			422,
			"LIMIT_REACHED",
			"Device registration limit reached",
			{ limit: 10 },
		);
	}
	return { id: result.id };
}

export async function removePushDevice(
	deps: AppDeps,
	input: { userId: string; id: string },
): Promise<void> {
	if (!deps.config.pushProvider) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const deleted = await deletePushDeviceForUser(deps.db, {
		id: input.id,
		userId: input.userId,
	});
	if (!deleted) {
		throw new AppError(404, "NOT_FOUND", "Push device not found");
	}
}

export async function updatePushSettings(
	deps: AppDeps,
	input: { userId: string; hideContent: boolean },
): Promise<{ hideContent: boolean }> {
	if (!deps.config.pushProvider) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const updated = await updateUserHidePushContent(deps.db, {
		userId: input.userId,
		hideContent: input.hideContent,
		now: deps.now(),
	});
	if (!updated) {
		throw new AppError(404, "NOT_FOUND", "User not found");
	}
	return { hideContent: input.hideContent };
}
