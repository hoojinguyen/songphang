import type { Metadata } from "next";
import type { ReactNode } from "react";
import { vi } from "../messages/vi";
import "./globals.css";
import "./fonts.css";
import { Providers } from "./providers";

export const metadata: Metadata = { title: vi.common.appName };

export default function RootLayout({ children }: { children: ReactNode }) {
	return (
		<html lang="vi" suppressHydrationWarning>
			<head>
				{/* Synchronous static script avoids first-paint theme flash without inline HTML injection. */}
				<script src="/theme-init.js" />
			</head>
			<body className="font-product bg-bg text-ink tabular-nums">
				<Providers>{children}</Providers>
			</body>
		</html>
	);
}
