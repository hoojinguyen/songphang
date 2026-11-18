function unsubscribeHeaders(unsubscribeUrl: string): Record<string, string> {
	return {
		"List-Unsubscribe": `<${unsubscribeUrl}>`,
		"List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
	};
}

function unsubscribeUrlFor(webOrigin: string, token: string): string {
	return `${webOrigin}/notifications/unsubscribe?token=${encodeURIComponent(token)}`;
}

export function immediateNotificationMail(input: {
	webOrigin: string;
	line: string;
	targetPath: string;
	unsubscribeToken: string;
}) {
	const targetUrl = `${input.webOrigin}${input.targetPath}`;
	const unsubscribeUrl = unsubscribeUrlFor(
		input.webOrigin,
		input.unsubscribeToken,
	);
	return {
		subject: input.line,
		headers: unsubscribeHeaders(unsubscribeUrl),
		text: [
			input.line,
			"",
			`Mở Sòng Phẳng: ${targetUrl}`,
			"",
			`Không muốn nhận thư nữa? Bỏ đăng ký: ${unsubscribeUrl}`,
		].join("\n"),
	};
}

export function digestMail(input: {
	webOrigin: string;
	lines: string[];
	overflowCount: number;
	unsubscribeToken: string;
}) {
	const unsubscribeUrl = unsubscribeUrlFor(
		input.webOrigin,
		input.unsubscribeToken,
	);
	const bodyLines = [...input.lines];
	if (input.overflowCount > 0) {
		bodyLines.push(`và ${input.overflowCount} cập nhật khác`);
	}
	return {
		subject: "Hôm nay trong các nhóm của bạn",
		headers: unsubscribeHeaders(unsubscribeUrl),
		text: [
			...bodyLines,
			"",
			`Mở Sòng Phẳng: ${input.webOrigin}/notifications`,
			"",
			`Không muốn nhận thư nữa? Bỏ đăng ký: ${unsubscribeUrl}`,
		].join("\n"),
	};
}
