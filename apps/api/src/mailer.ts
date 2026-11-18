export type Mailer = {
	send(mail: {
		to: string;
		subject: string;
		text: string;
		headers?: Record<string, string>;
		template?: string;
		userId?: string | null;
	}): Promise<void>;
};

export function createConsoleMailer(): Mailer {
	return {
		async send(mail) {
			console.log(
				JSON.stringify({
					event: "mail.sent",
					template: mail.template ?? "auth",
					userId: mail.userId ?? null,
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
