"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { type ReactNode, useState } from "react";
import { OfflineBanner } from "../components/ui/OfflineBanner";
export function Providers({ children }: { children: ReactNode }) {
	const [queryClient] = useState(
		() =>
			new QueryClient({
				defaultOptions: { mutations: { networkMode: "always", retry: false } },
			}),
	);
	return (
		<QueryClientProvider client={queryClient}>
			<OfflineBanner />
			{children}
		</QueryClientProvider>
	);
}
