import { createHash, randomBytes } from "node:crypto";
import { type DbExecutor, insertUnsubscribeTokenHash } from "@songphang/db";

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

export async function issueUnsubscribeToken(
	executor: DbExecutor,
	userId: string,
): Promise<string> {
	const token = randomBytes(32).toString("base64url");
	const tokenHash = createHash("sha256").update(token).digest("hex");
	await insertUnsubscribeTokenHash(executor, { userId, tokenHash });
	return token;
}
