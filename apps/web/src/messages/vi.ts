export const vi = {
	common: {
		appName: "Sòng Phẳng",
		logout: "Đăng xuất",
		retry: "Thử lại",
		loadError: "Không tải được. Kiểm tra mạng rồi thử lại.",
	},
	devLogin: {
		title: "Đăng nhập thử",
		hint: "Chỉ có ở môi trường phát triển. Chọn một người để vào.",
		enterAs: "Vào với tên {name}",
	},
	groups: {
		greeting: "Chào {name}",
		title: "Nhóm của bạn",
		emptyTitle: "Bạn chưa có nhóm nào",
		emptyHint: "Tạo một nhóm rồi gõ khoản chi đầu tiên.",
		create: "Tạo nhóm",
	},
	showcase: { members: { minh: "Minh", lan: "Lan", hung: "Hùng", thu: "Thu" } },
} as const;

export function t(template: string, vars: Record<string, string>): string {
	return template.replace(
		/\{([^{}]+)\}/g,
		(placeholder: string, key: string) =>
			Object.hasOwn(vars, key) ? (vars[key] ?? placeholder) : placeholder,
	);
}
