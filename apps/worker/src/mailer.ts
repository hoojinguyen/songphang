import { createHash, randomBytes } from "node:crypto";
import { type DbExecutor, upsertNotificationSettings } from "@songphang/db";

export type MailMessage = {
	to: string;
	subject: string;
	text: string;
	template: string;
	userId: string;
	headers?: Record<string, string>;
};

export type Mailer = {
	send(mail: MailMessage): Promise<void>;
};

export function createConsoleMailer(): Mailer {
	return {
		async send(mail) {
			console.log(
				JSON.stringify({
					event: "mail.sent",
					template: mail.template,
					userId: mail.userId,
				}),
			);
			const headerLines = Object.entries(mail.headers ?? {}).map(
				([key, value]) => `${key}: ${value}`,
			);
			console.log(
				[
					"--- Development mail ---",
					`To: ${mail.to}`,
					`Subject: ${mail.subject}`,
					...headerLines,
					mail.text,
					"--- End development mail ---",
				].join("\n"),
			);
		},
	};
}

const UNSUBSCRIBE_TOKEN_CACHE = new Map<string, string>();

export async function issueUnsubscribeToken(
	executor: DbExecutor,
	userId: string,
	existingHash: string | null,
): Promise<string> {
	const cached = UNSUBSCRIBE_TOKEN_CACHE.get(userId);
	if (cached && existingHash) {
		const cachedHash = createHash("sha256").update(cached).digest("hex");
		if (cachedHash === existingHash) return cached;
	}
	const token = randomBytes(32).toString("base64url");
	const tokenHash = createHash("sha256").update(token).digest("hex");
	await upsertNotificationSettings(executor, {
		userId,
		unsubscribeTokenHash: tokenHash,
	});
	UNSUBSCRIBE_TOKEN_CACHE.set(userId, token);
	return token;
}
