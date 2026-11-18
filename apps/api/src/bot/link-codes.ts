import { createHash, randomInt } from "node:crypto";

const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 8;
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
