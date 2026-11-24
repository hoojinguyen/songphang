import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

const VERSION_PREFIX = "v1:";
const IV_LENGTH = 12;
const TAG_LENGTH = 16;

function assertValidKey(key: Buffer): void {
	if (key.length !== 32) {
		throw new Error("DATA_ENCRYPTION_KEY must be 32 bytes");
	}
}

export function encryptSecret(plaintext: string, key: Buffer): string {
	assertValidKey(key);
	const iv = randomBytes(IV_LENGTH);
	const cipher = createCipheriv("aes-256-gcm", key, iv);
	const ciphertext = Buffer.concat([
		cipher.update(plaintext, "utf8"),
		cipher.final(),
	]);
	const tag = cipher.getAuthTag();
	return `${VERSION_PREFIX}${Buffer.concat([iv, ciphertext, tag]).toString("base64")}`;
}

export function decryptSecret(sealed: string, key: Buffer): string {
	assertValidKey(key);
	if (!sealed.startsWith(VERSION_PREFIX)) {
		throw new Error("Unsupported encrypted secret format");
	}
	const payload = Buffer.from(sealed.slice(VERSION_PREFIX.length), "base64");
	if (payload.length < IV_LENGTH + TAG_LENGTH) {
		throw new Error("Encrypted secret is truncated");
	}
	const iv = payload.subarray(0, IV_LENGTH);
	const tag = payload.subarray(payload.length - TAG_LENGTH);
	const ciphertext = payload.subarray(IV_LENGTH, payload.length - TAG_LENGTH);
	const decipher = createDecipheriv("aes-256-gcm", key, iv);
	decipher.setAuthTag(tag);
	return Buffer.concat([
		decipher.update(ciphertext),
		decipher.final(),
	]).toString("utf8");
}
