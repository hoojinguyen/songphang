import { createHash, randomBytes, randomInt } from "node:crypto";

const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 8;
const PAIRING_SECRET_PREFIX = "pair_";
export const LINK_CODE_TTL_MS = 10 * 60 * 1000;

export function generateLinkCode(): string {
	let code = "";
	for (let i = 0; i < CODE_LENGTH; i++) {
		code += CODE_ALPHABET[randomInt(0, CODE_ALPHABET.length)];
	}
	return code;
}

export function hashLinkCode(rawCode: string): string {
	return createHash("sha256")
		.update(rawCode.trim().toUpperCase(), "utf8")
		.digest("hex");
}

export function generatePairingSecret(): string {
	return `${PAIRING_SECRET_PREFIX}${randomBytes(24).toString("base64url")}`;
}

export function hashPairingSecret(rawSecret: string): string {
	return createHash("sha256").update(rawSecret.trim(), "utf8").digest("hex");
}

export function isValidPairingSecretFormat(rawSecret: string): boolean {
	return /^[A-Za-z0-9_-]{16,64}$/.test(rawSecret.trim());
}
