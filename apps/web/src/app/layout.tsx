import type { Metadata } from "next";
import type { ReactNode } from "react";
import { vi } from "../messages/vi";
import "./globals.css";
import "./fonts.css";
import { Providers } from "./providers";

export const metadata: Metadata = { title: vi.common.appName };

export default function RootLayout({ children }: { children: ReactNode }) {
	return (
		<html lang="vi">
			<body className="font-product bg-bg text-ink">
				<Providers>{children}</Providers>
			</body>
		</html>
	);
}
