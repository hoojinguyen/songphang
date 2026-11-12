import {
	type Argon2Parameters,
	argon2,
	randomBytes,
	timingSafeEqual,
} from "node:crypto";
import { readFileSync } from "node:fs";

const COMMON_PASSWORDS = new Set(
	readFileSync(new URL("./common-passwords.txt", import.meta.url), "utf8")
		.split(/\r?\n/)
		.filter(Boolean),
);
function derivePassword(parameters: Argon2Parameters): Promise<Buffer> {
	return new Promise((resolve, reject) =>
		argon2("argon2id", parameters, (error, hash) => {
			if (error) reject(error);
			else resolve(hash);
		}),
	);
}
function encodeBase64(value: Buffer) {
	return value.toString("base64").replace(/=+$/, "");
}
export async function hashPassword(password: string): Promise<string> {
	const salt = randomBytes(16);
	const hash = await derivePassword({
		message: password,
		nonce: salt,
		memory: 19456,
		passes: 2,
		parallelism: 1,
		tagLength: 32,
	});
	return `$argon2id$v=19$m=19456,t=2,p=1$${encodeBase64(salt)}$${encodeBase64(hash)}`;
}
export async function verifyPassword(
	password: string,
	phc: string,
): Promise<boolean> {
	const match =
		/^\$argon2id\$v=19\$m=(\d{1,6}),t=(\d{1,2}),p=(\d{1,2})\$([A-Za-z0-9+/]{22,86})\$([A-Za-z0-9+/]{22,86})$/.exec(
			phc,
		);
	if (!match) return false;
	const [, memoryText, passesText, parallelismText, saltText, hashText] = match;
	if (!memoryText || !passesText || !parallelismText || !saltText || !hashText)
		return false;
	const memory = Number(memoryText),
		passes = Number(passesText),
		parallelism = Number(parallelismText);
	const salt = Buffer.from(saltText, "base64"),
		expected = Buffer.from(hashText, "base64");
	if (
		memory < 8 * parallelism ||
		memory > 262144 ||
		passes < 1 ||
		passes > 10 ||
		parallelism < 1 ||
		parallelism > 16 ||
		salt.length < 16 ||
		expected.length < 16 ||
		expected.length > 64 ||
		encodeBase64(salt) !== saltText ||
		encodeBase64(expected) !== hashText
	)
		return false;
	try {
		const derived = await derivePassword({
			message: password,
			nonce: salt,
			memory,
			passes,
			parallelism,
			tagLength: expected.length,
		});
		return timingSafeEqual(derived, expected);
	} catch {
		return false;
	}
}
export const DUMMY_PASSWORD_HASH = await hashPassword(
	randomBytes(32).toString("base64url"),
);
export function checkNewPassword(
	password: string,
): "ok" | "too_short" | "too_long" | "too_common" {
	if (password.length < 10) return "too_short";
	if (password.length > 128) return "too_long";
	const normalized = password.toLowerCase();
	const stripped = normalized.replace(/[\d\p{P}\p{S}]+$/u, "");
	return COMMON_PASSWORDS.has(normalized) || COMMON_PASSWORDS.has(stripped)
		? "too_common"
		: "ok";
}
