import { createHash, randomBytes } from "node:crypto";
import {
	type MobileExchangeRequest,
	PkceCodeChallenge,
	UserDto,
} from "@songphang/contract";
import {
	consumeMobileExchangeToken,
	type DbSessionClient,
	findUserById,
	insertAuthToken,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { createSession } from "../auth/sessions.js";
import { AppError } from "../errors.js";

const MOBILE_EXCHANGE_TTL_MS = 60 * 1000;
const EXCHANGE_CODE_PATTERN = /^[A-Za-z0-9_-]{43}$/;

export async function issueMobileExchangeCode(
	deps: AppDeps,
	input: {
		userId: string;
		codeChallenge: string;
		client: "ios" | "android";
	},
): Promise<string> {
	const codeChallenge = PkceCodeChallenge.parse(input.codeChallenge);
	const code = randomBytes(32).toString("base64url");
	const tokenHash = createHash("sha256").update(code).digest("hex");
	const now = deps.now();
	await insertAuthToken(deps.db, {
		userId: input.userId,
		purpose: "mobile_exchange",
		tokenHash,
		codeChallenge,
		client: input.client,
		expiresAt: new Date(now.getTime() + MOBILE_EXCHANGE_TTL_MS),
		createdAt: now,
	});
	return code;
}

export async function exchangeMobileCode(
	deps: AppDeps,
	input: {
		request: MobileExchangeRequest;
		userAgent?: string;
	},
) {
	if (!EXCHANGE_CODE_PATTERN.test(input.request.code)) {
		throw new AppError(
			400,
			"TOKEN_INVALID",
			"Exchange code is invalid or expired",
		);
	}
	const tokenHash = createHash("sha256")
		.update(input.request.code)
		.digest("hex");
	const codeChallenge = createHash("sha256")
		.update(input.request.codeVerifier)
		.digest("base64url");

	return deps.db.transaction(async (transaction) => {
		const now = deps.now();
		const userId = await consumeMobileExchangeToken(transaction, {
			tokenHash,
			codeChallenge,
			client: input.request.client as Extract<
				DbSessionClient,
				"ios" | "android"
			>,
			now,
		});
		if (userId === null) {
			throw new AppError(
				400,
				"TOKEN_INVALID",
				"Exchange code is invalid or expired",
			);
		}
		const userRow = await findUserById(transaction, userId);
		if (userRow === null) {
			throw new AppError(
				400,
				"TOKEN_INVALID",
				"Exchange code is invalid or expired",
			);
		}
		const session = await createSession(transaction, {
			userId,
			now,
			client: input.request.client,
			deviceName: input.request.deviceName,
			...(input.userAgent === undefined ? {} : { userAgent: input.userAgent }),
		});
		return { session, user: UserDto.parse(userRow) };
	});
}
