import { createPrivateKey, sign } from "node:crypto";

const PROVIDER_TOKEN_TTL_SECONDS = 50 * 60;

export function createApnsProviderJwt(input: {
	teamId: string;
	keyId: string;
	privateKey: string;
	issuedAtSeconds: number;
}): string {
	const header = Buffer.from(
		JSON.stringify({ alg: "ES256", kid: input.keyId }),
	).toString("base64url");
	const payload = Buffer.from(
		JSON.stringify({ iss: input.teamId, iat: input.issuedAtSeconds }),
	).toString("base64url");
	const signingInput = `${header}.${payload}`;
	const key = createPrivateKey(input.privateKey);
	const signature = sign("sha256", Buffer.from(signingInput), {
		key,
		dsaEncoding: "ieee-p1363",
	}).toString("base64url");
	return `${signingInput}.${signature}`;
}

export type ApnsProviderTokenSource = {
	getToken(): string;
	invalidate(): void;
};

export function createApnsProviderTokenSource(input: {
	teamId: string;
	keyId: string;
	privateKey: string;
	now: () => Date;
}): ApnsProviderTokenSource {
	let cachedJwt: string | null = null;
	let cachedAtSeconds = -1;

	return {
		getToken(): string {
			const nowSeconds = Math.floor(input.now().getTime() / 1000);
			if (
				cachedJwt === null ||
				cachedAtSeconds < 0 ||
				nowSeconds - cachedAtSeconds >= PROVIDER_TOKEN_TTL_SECONDS
			) {
				cachedJwt = createApnsProviderJwt({
					teamId: input.teamId,
					keyId: input.keyId,
					privateKey: input.privateKey,
					issuedAtSeconds: nowSeconds,
				});
				cachedAtSeconds = nowSeconds;
			}
			return cachedJwt;
		},
		invalidate(): void {
			cachedJwt = null;
			cachedAtSeconds = -1;
		},
	};
}
