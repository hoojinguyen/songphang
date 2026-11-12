import { createHash } from "node:crypto";
import { z } from "@hono/zod-openapi";
import { EmailAddress } from "@songphang/contract";
import type { Config } from "../config.js";
export const GoogleClaims = z.object({
	sub: z.string().min(1).max(255),
	email: EmailAddress,
	email_verified: z.literal(true),
	name: z.string().trim().min(1).max(50),
	picture: z
		.url({ protocol: /^https$/ })
		.max(2048)
		.optional(),
});
export type GoogleClaims = z.infer<typeof GoogleClaims>;
export function safeRedirect(raw: string | undefined): string {
	if (
		!raw?.startsWith("/") ||
		raw.startsWith("//") ||
		raw.includes("\\") ||
		Array.from(raw).some(
			(character) =>
				character.charCodeAt(0) < 32 || character.charCodeAt(0) === 127,
		)
	)
		return "/";
	return raw;
}
export function googleAuthorizationUrl(
	config: Config,
	input: { state: string; verifier: string },
): string {
	const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
	url.search = new URLSearchParams({
		client_id: config.googleClientId ?? "",
		redirect_uri: `${config.webOrigin}/api/v1/auth/google/callback`,
		response_type: "code",
		scope: "openid email profile",
		state: input.state,
		code_challenge: createHash("sha256")
			.update(input.verifier)
			.digest("base64url"),
		code_challenge_method: "S256",
	}).toString();
	return url.toString();
}
export async function exchangeGoogleCode(
	config: Config,
	input: { code: string; verifier: string },
): Promise<GoogleClaims> {
	if (!config.googleClientId || !config.googleClientSecret)
		throw new Error("Google sign-in is not configured");
	const response = await fetch("https://oauth2.googleapis.com/token", {
		method: "POST",
		redirect: "error",
		signal: AbortSignal.timeout(10000),
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		body: new URLSearchParams({
			client_id: config.googleClientId ?? "",
			client_secret: config.googleClientSecret ?? "",
			code: input.code,
			code_verifier: input.verifier,
			grant_type: "authorization_code",
			redirect_uri: `${config.webOrigin}/api/v1/auth/google/callback`,
		}),
	});
	if (!response.ok) throw new Error("Google token exchange failed");
	const tokens = z
		.object({ id_token: z.string().max(16384) })
		.parse(await response.json());
	const segments = tokens.id_token.split(".");
	const payload = segments[1];
	if (segments.length !== 3 || !payload || !/^[A-Za-z0-9_-]+$/.test(payload))
		throw new Error("Invalid Google ID token");
	return GoogleClaims.parse(
		JSON.parse(Buffer.from(payload, "base64url").toString("utf8")),
	);
}
