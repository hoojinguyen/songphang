"use client";
import { useQueryClient } from "@tanstack/react-query";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import type { ApiError } from "./api";
import { loginPath } from "./session";
export function useSessionGuard(error: ApiError | null): void {
	const router = useRouter();
	const client = useQueryClient();
	const pathname = usePathname();
	useEffect(() => {
		if (error?.status !== 401) return;
		const returnTo = pathname + window.location.search;
		void client.cancelQueries().then(() => {
			client.clear();
			router.replace(loginPath(returnTo));
		});
	}, [client, error, pathname, router]);
}
