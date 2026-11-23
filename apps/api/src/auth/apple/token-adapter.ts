import { createHash, createPrivateKey, sign } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { z } from "@hono/zod-openapi";
import type { Config } from "../../config.js";
import { AppError } from "../../errors.js";

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

export class AppleTokenAdapterError extends Error {
	constructor(
		message: string,
		public readonly category: string,
	) {
		super(message);
		this.name = "AppleTokenAdapterError";
	}
}

const AppleErrorResponseSchema = z
	.object({
		error: z.string().max(100),
	})
	.passthrough();

const KNOWN_APPLE_ERROR_TYPES = new Set([
	"invalid_request",
	"invalid_client",
	"invalid_grant",
	"unauthorized_client",
	"unsupported_grant_type",
]);

export type AppleTokenExchangeResult = {
	refreshToken: string | null;
	idToken?: string;
	subject?: string;
};

export type AppleTokenAdapter = {
	exchangeAuthorizationCode(code: string): Promise<AppleTokenExchangeResult>;
	revokeRefreshToken(input: {
		refreshToken: string | null;
		userId: string;
	}): Promise<void>;
};

export function createAppleClientSecret(
	config: {
		appleBundleId: string;
		appleTeamId: string;
		appleKeyId: string;
		applePrivateKey: string;
	},
	now: Date,
): string {
	const header = Buffer.from(
		JSON.stringify({ alg: "ES256", kid: config.appleKeyId }),
	).toString("base64url");
	const iat = Math.floor(now.getTime() / 1000);
	const payload = Buffer.from(
		JSON.stringify({
			iss: config.appleTeamId,
			iat,
			exp: iat + 300,
			aud: "https://appleid.apple.com",
			sub: config.appleBundleId,
		}),
	).toString("base64url");
	const signingInput = `${header}.${payload}`;
	const privateKey = createPrivateKey(config.applePrivateKey);
	const signature = sign("sha256", Buffer.from(signingInput), {
		key: privateKey,
		dsaEncoding: "ieee-p1363",
	}).toString("base64url");
	return `${signingInput}.${signature}`;
}

async function consumeFakeCode(jwksPath: string, code: string): Promise<void> {
	const fixture = createHash("sha256")
		.update(await readFile(jwksPath))
		.digest("hex");
	const directory = join(`${jwksPath}.replay`, fixture);
	const digest = createHash("sha256").update(code).digest("hex");
	await mkdir(directory, { recursive: true, mode: 0o700 });
	try {
		await writeFile(join(directory, digest), "", { flag: "wx", mode: 0o600 });
	} catch (error) {
		if (error instanceof Error && "code" in error && error.code === "EEXIST") {
			throw new AppError(
				401,
				"INVALID_CREDENTIALS",
				"Apple authorization code has already been used",
			);
		}
		throw error;
	}
}

export function createAppleTokenAdapter(
	config: Config,
	now: () => Date,
): AppleTokenAdapter {
	return {
		async exchangeAuthorizationCode(
			code: string,
		): Promise<AppleTokenExchangeResult> {
			if (config.appleProvider === "fake") {
				if (!config.appleFakeJwksFile)
					throw new Error("Fake Apple JWKS is not configured");
				await consumeFakeCode(config.appleFakeJwksFile, code);
				if (code.startsWith("sub=")) {
					const afterPrefix = code.slice(4);
					const separator = afterPrefix.indexOf(":");
					const subject =
						separator >= 0 ? afterPrefix.slice(0, separator) : afterPrefix;
					return { refreshToken: "fake-refresh-token", subject };
				}
				return { refreshToken: "fake-refresh-token" };
			}
			if (
				config.appleProvider !== "apple" ||
				!config.appleBundleId ||
				!config.appleTeamId ||
				!config.appleKeyId ||
				!config.applePrivateKey
			) {
				throw new Error("Apple token exchange is not configured");
			}
			const clientSecret = createAppleClientSecret(
				{
					appleBundleId: config.appleBundleId,
					appleTeamId: config.appleTeamId,
					appleKeyId: config.appleKeyId,
					applePrivateKey: config.applePrivateKey,
				},
				now(),
			);
			const response = await fetch(APPLE_TOKEN_URL, {
				method: "POST",
				redirect: "error",
				signal: AbortSignal.timeout(10_000),
				headers: { "Content-Type": "application/x-www-form-urlencoded" },
				body: new URLSearchParams({
					client_id: config.appleBundleId,
					client_secret: clientSecret,
					code,
					grant_type: "authorization_code",
				}),
			});
			if (response.status === 400) {
				let errorType = "";
				try {
					const json = await response.json();
					const parsed = AppleErrorResponseSchema.safeParse(json);
					if (parsed.success) {
						errorType = parsed.data.error;
					}
				} catch {
					// Malformed or non-JSON body
				}
				if (errorType === "invalid_grant") {
					throw new AppError(
						401,
						"INVALID_CREDENTIALS",
						"Apple authorization code is invalid or already used",
					);
				}
				if (errorType) {
					const category = KNOWN_APPLE_ERROR_TYPES.has(errorType)
						? `rejected:${errorType}`
						: "rejected:unknown";
					throw new AppleTokenAdapterError(
						`Apple token exchange rejected: ${errorType}`,
						category,
					);
				}
				throw new AppleTokenAdapterError(
					"Apple token exchange failed with malformed 400 response",
					"malformed_response",
				);
			}
			if (!response.ok) {
				throw new AppleTokenAdapterError(
					`Apple token exchange failed with status ${response.status}`,
					`http_status:${response.status}`,
				);
			}
			const body = z
				.object({
					refresh_token: z.string().min(1),
					id_token: z.string().min(1),
				})
				.parse(await response.json());
			return {
				refreshToken: body.refresh_token,
				idToken: body.id_token,
			};
		},

		async revokeRefreshToken(input: {
			refreshToken: string | null;
			userId: string;
		}): Promise<void> {
			if (config.appleProvider === "fake") {
				console.log(
					JSON.stringify({
						event: "apple.revoke.simulated",
						userId: input.userId,
					}),
				);
				return;
			}
			if (
				config.appleProvider !== "apple" ||
				!config.appleBundleId ||
				!config.appleTeamId ||
				!config.appleKeyId ||
				!config.applePrivateKey ||
				!input.refreshToken
			) {
				throw new Error("Apple token revocation prerequisites missing");
			}
			const clientSecret = createAppleClientSecret(
				{
					appleBundleId: config.appleBundleId,
					appleTeamId: config.appleTeamId,
					appleKeyId: config.appleKeyId,
					applePrivateKey: config.applePrivateKey,
				},
				now(),
			);
			const response = await fetch(APPLE_REVOKE_URL, {
				method: "POST",
				redirect: "error",
				signal: AbortSignal.timeout(10_000),
				headers: { "Content-Type": "application/x-www-form-urlencoded" },
				body: new URLSearchParams({
					client_id: config.appleBundleId,
					client_secret: clientSecret,
					token: input.refreshToken,
					token_type_hint: "refresh_token",
				}),
			});
			if (!response.ok) {
				throw new AppleTokenAdapterError(
					`Apple token revocation failed with status ${response.status}`,
					`http_status:${response.status}`,
				);
			}
		},
	};
}
