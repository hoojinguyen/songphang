import { formatMoney } from "@songphang/core";

export const BOT_MESSAGES = {
	chatLinked: (group: string) =>
		`Đã liên kết nhóm chat này với sổ "${group}". Gõ /chi rồi khoản chi, ví dụ: /chi cà phê 180k chia 4`,
	badOrExpiredCode:
		"Mã liên kết không đúng hoặc đã hết hạn. Hãy lấy mã mới trong cài đặt nhóm.",
	chatNotLinked:
		"Nhóm chat này chưa liên kết với sổ nào. Chủ nhóm lấy mã trong cài đặt nhóm trên Sòng Phẳng.",
	senderNotLinked: "Mình chưa biết bạn là ai trên Sòng Phẳng.",
	linkAccountButton: "Liên kết tài khoản",
	notInGroup: (group: string) => `Bạn chưa ở trong sổ "${group}".`,
	viewerCannotAdd: "Bạn chỉ có quyền xem sổ này.",
	groupArchived: "Sổ này đã lưu trữ — chỉ xem.",
	chiEmpty: "Gõ khoản chi sau /chi, ví dụ: /chi lẩu 600k chia 4",
	notUnderstood: (issueText: string) =>
		`Mình chưa đọc được câu này: ${issueText}.`,
	openFormButton: "Mở form",
	saveButton: "Lưu",
	dropButton: "Bỏ",
	saved: (description: string, amount: number, pendingOwner?: string) => {
		const base = `Đã lưu: ${description} · ${formatMoney(amount)}.`;
		return pendingOwner ? `${base} Khoản này chờ ${pendingOwner} duyệt.` : base;
	},
	dropped: "Đã bỏ.",
	draftExpired: "Khoản này đã quá 10 phút. Hãy gõ lại.",
	onlySenderCanSave: (name: string) => `Chỉ ${name} lưu được khoản này.`,
	huyDone: (description: string, amount: number) =>
		`Đã xoá: ${description} · ${formatMoney(amount)}.`,
	huyNothing: "Không có khoản nào của bạn trong 10 phút qua.",
	help: "/chi <khoản chi> — thêm khoản chi\n/sodu — xem ai nợ ai\n/huy — xoá khoản bạn vừa thêm",
	tooManyMessages: "Chậm lại một chút nhé.",
	pairingPrivateOnly:
		"Vì lý do bảo mật, chỉ gửi mã liên kết tài khoản trong tin nhắn riêng với bot. Hãy tạo mã mới trên Sòng Phẳng.",
	pairingInvalidOrExpired:
		"Mã liên kết tài khoản không đúng hoặc đã hết hạn. Hãy bắt đầu lại trên Sòng Phẳng.",
	pairingIdentityTaken:
		"Tài khoản Telegram này đã liên kết với một tài khoản Sòng Phẳng khác.",
	pairingPrompt: (name: string, maskedEmail: string) =>
		`Liên kết Telegram này với tài khoản Sòng Phẳng "${name}" (${maskedEmail})?`,
	pairingConfirmButton: "Xác nhận liên kết",
	pairingCancelButton: "Huỷ",
	pairingTelegramConfirmed:
		"Đã xác nhận trên Telegram. Hãy quay lại trình duyệt Sòng Phẳng để hoàn tất liên kết.",
	pairingCancelled: "Đã huỷ liên kết tài khoản.",
	privateStartHelp:
		"Để liên kết tài khoản Telegram, hãy mở Sòng Phẳng trên trình duyệt và bắt đầu liên kết tài khoản.",
};

export function maskEmail(email: string): string {
	const atIndex = email.indexOf("@");
	if (atIndex <= 0) return "***";
	const local = email.slice(0, atIndex);
	const domain = email.slice(atIndex + 1);
	if (local.length === 1) return `*@${domain}`;
	if (local.length === 2) return `${local[0]}*@${domain}`;
	return `${local[0]}***${local[local.length - 1]}@${domain}`;
}

export function formatParseIssue(input: {
	code: string;
	snippet: string;
}): string {
	switch (input.code) {
		case "AMOUNT_MISSING":
			return "thiếu số tiền";
		case "MEMBER_UNKNOWN":
			return `không biết "${input.snippet}" là ai`;
		case "MEMBER_AMBIGUOUS":
			return `"${input.snippet}" khớp nhiều người`;
		case "COUNT_MISMATCH":
			return "số người chia không khớp";
		case "SUM_MISMATCH":
			return "các số không cộng lại đúng";
		default:
			return `chưa hiểu "${input.snippet}"`;
	}
}

export function formatBotDraftText(input: {
	reader: "rules" | "ai";
	description: string;
	amount: number;
	payerNames: string[];
	shares: Array<{ name: string; amount: number }>;
}): string {
	const lines: string[] = [];
	if (input.reader === "ai") {
		lines.push("Đọc bằng AI.");
	}
	lines.push(`${input.description} · ${formatMoney(input.amount)}`);
	lines.push(`${input.payerNames.join(", ")} trả`);
	for (const share of input.shares) {
		lines.push(`${share.name}: ${formatMoney(share.amount)}`);
	}
	return lines.join("\n");
}

export function formatBotBalancesText(input: {
	groupName: string;
	fundCash: number | null;
	balances: Array<{ name: string; balance: number }>;
	transfers: Array<{ fromName: string; toName: string; amount: number }>;
}): string {
	const lines: string[] = [`Sổ "${input.groupName}"`];
	if (input.fundCash !== null) {
		lines.push(`Quỹ còn ${formatMoney(input.fundCash)}`);
	}
	for (const entry of input.balances) {
		if (entry.balance > 0) {
			lines.push(`${entry.name}: được nhận ${formatMoney(entry.balance)}`);
		} else if (entry.balance < 0) {
			lines.push(`${entry.name}: cần trả ${formatMoney(-entry.balance)}`);
		} else {
			lines.push(`${entry.name}: đã xong`);
		}
	}
	for (const transfer of input.transfers) {
		lines.push(
			`${transfer.fromName} → ${transfer.toName}: ${formatMoney(transfer.amount)}`,
		);
	}
	return lines.join("\n");
}
