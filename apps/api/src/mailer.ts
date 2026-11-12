export type Mailer = {
	send(mail: { to: string; subject: string; text: string }): Promise<void>;
};
export function createConsoleMailer(): Mailer {
	return {
		async send(mail) {
			console.log(
				[
					"--- Development mail ---",
					`To: ${mail.to}`,
					`Subject: ${mail.subject}`,
					mail.text,
					"--- End development mail ---",
				].join("\n"),
			);
		},
	};
}
