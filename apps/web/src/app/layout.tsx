import type { Metadata } from "next";
import { Be_Vietnam_Pro } from "next/font/google";
import type { ReactNode } from "react";
import { vi } from "../messages/vi";
import "./globals.css";

const beVietnamPro = Be_Vietnam_Pro({
	weight: ["400", "500", "600", "700", "800", "900"],
	subsets: ["vietnamese"],
	display: "swap",
});

export const metadata: Metadata = { title: vi.common.appName };

export default function RootLayout({ children }: { children: ReactNode }) {
	return (
		<html lang="vi">
			<body className={`${beVietnamPro.className} bg-bg text-ink`}>
				{children}
			</body>
		</html>
	);
}
