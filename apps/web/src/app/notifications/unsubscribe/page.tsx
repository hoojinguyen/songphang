"use client";
import { useMutation } from "@tanstack/react-query";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useRef } from "react";
import { LoadError } from "../../../components/ui/LoadError";
import type { ApiError } from "../../../lib/api";
import { postUnsubscribe } from "../../../lib/notifications";
import { vi } from "../../../messages/vi";

function UnsubscribeScreen() {
	const token = useSearchParams().get("token");
	const started = useRef(false);
	const mutation = useMutation<void, ApiError, string>({
		mutationFn: postUnsubscribe,
	});

	useEffect(() => {
		if (token && !started.current) {
			started.current = true;
			mutation.mutate(token);
		}
	}, [token, mutation.mutate]);

	const invalid = !token || mutation.error?.status === 404;

	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
			{mutation.isSuccess ? (
				<>
					<h1 className="text-[24px] font-black">
						{vi.notifications.unsubscribeSuccess}
					</h1>
					<Link
						href="/account"
						className="flex h-control-lg items-center justify-center rounded-pill bg-ink px-6 font-bold text-surface"
					>
						{vi.notifications.unsubscribeReenable}
					</Link>
				</>
			) : invalid ? (
				<>
					<h1 className="text-[24px] font-black">
						{vi.notifications.unsubscribeInvalid}
					</h1>
					<Link
						href="/"
						className="flex h-control-md items-center justify-center rounded-pill bg-surface px-6 font-bold"
					>
						{vi.common.backToGroups}
					</Link>
				</>
			) : mutation.isError ? (
				<LoadError
					isRetrying={mutation.isPending}
					onRetry={() => {
						if (token) mutation.mutate(token);
					}}
				/>
			) : (
				<div aria-busy="true" className="h-32 rounded-card bg-sunken" />
			)}
		</main>
	);
}

export default function UnsubscribePage() {
	return (
		<Suspense fallback={<main aria-busy="true" className="min-h-dvh" />}>
			<UnsubscribeScreen />
		</Suspense>
	);
}
