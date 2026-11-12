"use client";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import type { ApiError } from "./api";
import { loginPath } from "./session";
export function useSessionGuard(error: ApiError | null): void {
	const router = useRouter();
	const pathname = usePathname();
	useEffect(() => {
		if (error?.status === 401)
			router.replace(loginPath(pathname + window.location.search));
	}, [error, pathname, router]);
}
