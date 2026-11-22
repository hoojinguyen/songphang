import { createPrivateKey, sign } from "node:crypto";
import { z } from "@hono/zod-openapi";
import type { Config } from "../../config.js";

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

export type AppleTokenAdapter = {
	exchangeAuthorizationCode(code: string): Promise<string | null>;
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

export function createAppleTokenAdapter(
	config: Config,
	now: () => Date,
): AppleTokenAdapter {
	return {
		async exchangeAuthorizationCode(code: string): Promise<string | null> {
			if (config.appleProvider === "fake") {
				return null;
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
			if (!response.ok) {
				throw new Error("Apple token exchange failed");
			}
			const body = z
				.object({ refresh_token: z.string().min(1) })
				.parse(await response.json());
			return body.refresh_token;
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
				throw new Error("Apple token revocation failed");
			}
		},
	};
}
