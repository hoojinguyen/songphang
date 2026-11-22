import { createPublicKey, type KeyObject } from "node:crypto";
import { readFile } from "node:fs/promises";
import { z } from "@hono/zod-openapi";
import type { Config } from "../../config.js";

const APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const UNKNOWN_KID_COOLDOWN_MS = 60 * 1000;

const JwkSchema = z.object({
	kty: z.literal("RSA"),
	kid: z.string().min(1).max(256),
	use: z.string().optional(),
	alg: z.string().optional(),
	n: z.string().min(1),
	e: z.string().min(1),
});

const JwksSchema = z.object({
	keys: z.array(JwkSchema).max(64),
});

export type AppleKeySetProvider = {
	getKey(kid: string): Promise<KeyObject | null>;
};

export function createAppleKeySetProvider(
	config: Config,
	now: () => Date,
): AppleKeySetProvider {
	let keys = new Map<string, KeyObject>();
	let fetchedAtMs: number | null = null;
	let lastUnknownRefreshMs = Number.NEGATIVE_INFINITY;
	let inflight: Promise<Map<string, KeyObject>> | null = null;

	async function loadKeys(): Promise<Map<string, KeyObject>> {
		let rawText: string;
		if (config.appleProvider === "fake") {
			if (!config.appleFakeJwksFile) {
				throw new Error("APPLE_FAKE_JWKS_FILE is not configured");
			}
			rawText = await readFile(config.appleFakeJwksFile, "utf8");
		} else {
			const response = await fetch(APPLE_KEYS_URL, {
				redirect: "error",
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) {
				throw new Error("Failed to fetch Apple public keys");
			}
			rawText = await response.text();
		}
		const parsed = JwksSchema.parse(JSON.parse(rawText));
		const nextKeys = new Map<string, KeyObject>();
		for (const jwk of parsed.keys) {
			if (jwk.alg !== undefined && jwk.alg !== "RS256") continue;
			nextKeys.set(
				jwk.kid,
				createPublicKey({
					key: { kty: jwk.kty, n: jwk.n, e: jwk.e },
					format: "jwk",
				}),
			);
		}
		keys = nextKeys;
		fetchedAtMs = now().getTime();
		return nextKeys;
	}

	async function refresh(): Promise<Map<string, KeyObject>> {
		if (!inflight) {
			inflight = loadKeys().finally(() => {
				inflight = null;
			});
		}
		return inflight;
	}

	return {
		async getKey(kid: string): Promise<KeyObject | null> {
			const currentMs = now().getTime();
			const isExpired =
				fetchedAtMs === null || currentMs - fetchedAtMs >= CACHE_TTL_MS;
			if (isExpired) {
				await refresh();
			}
			const cached = keys.get(kid);
			if (cached) return cached;
			if (
				!isExpired &&
				currentMs - lastUnknownRefreshMs >= UNKNOWN_KID_COOLDOWN_MS
			) {
				lastUnknownRefreshMs = currentMs;
				await refresh();
				return keys.get(kid) ?? null;
			}
			return null;
		},
	};
}
