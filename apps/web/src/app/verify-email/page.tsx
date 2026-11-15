"use client";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useRef } from "react";
import { Button } from "../../components/ui/Button";
import { LoadError } from "../../components/ui/LoadError";
import {
	authErrorMessage,
	useResendVerification,
	useVerifyEmail,
} from "../../lib/auth";
import { useMe } from "../../lib/session";
import { vi } from "../../messages/vi";

function VerifyScreen() {
	const token = useSearchParams().get("token");
	const started = useRef(false);
	const mutation = useVerifyEmail();
	const me = useMe();
	const resend = useResendVerification();
	useEffect(() => {
		if (token && !started.current) {
			started.current = true;
			mutation.mutate(token);
		}
	}, [token, mutation.mutate]);
	const invalid = !token || mutation.error?.code === "TOKEN_INVALID";
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
			{mutation.isSuccess ? (
				<>
					<h1 className="text-[28px] font-black">{vi.verify.success}</h1>
					<Link
						href="/"
						className="flex h-control-lg items-center justify-center rounded-pill bg-ink font-bold text-surface"
					>
						{vi.verify.enter}
					</Link>
				</>
			) : invalid ? (
				<>
					<h1 className="text-[28px] font-black">{vi.verify.invalid}</h1>
					{me.data ? (
						<>
							<Button
								variant="surface"
								onClick={() => resend.mutate()}
								disabled={resend.isPending}
							>
								{vi.verify.resend}
							</Button>
							{resend.isSuccess && <p role="status">{vi.verify.resent}</p>}
							{resend.isError && (
								<p role="alert">{authErrorMessage(resend.error)}</p>
							)}
						</>
					) : (
						<Link
							href="/login"
							className="flex min-h-11 items-center justify-center rounded-pill bg-surface"
						>
							{vi.login.submit}
						</Link>
					)}
				</>
			) : mutation.isError ? (
				<LoadError
					onRetry={() => {
						if (token) mutation.mutate(token);
					}}
					isRetrying={mutation.isPending}
				/>
			) : (
				<div aria-busy="true" className="h-40 rounded-card bg-sunken" />
			)}
		</main>
	);
}
export default function VerifyEmailPage() {
	return (
		<Suspense
			fallback={
				<main
					aria-busy="true"
					className="mx-auto h-dvh max-w-[430px] bg-sunken"
				/>
			}
		>
			<VerifyScreen />
		</Suspense>
	);
}
