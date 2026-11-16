"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { Button } from "../../components/ui/Button";
import { LoadError } from "../../components/ui/LoadError";
import { LoginShapes } from "../../components/ui/LoginShapes";
import { TextField } from "../../components/ui/TextField";
import { authErrorMessage, useLogin, useProviders } from "../../lib/auth";
import { safeNext, useMe } from "../../lib/session";
import { vi } from "../../messages/vi";

function LoginScreen() {
	const params = useSearchParams();
	const next = safeNext(params.get("next"));
	const router = useRouter();
	const me = useMe();
	const client = useQueryClient();
	const providers = useProviders();
	const login = useLogin();
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	useEffect(() => {
		if (me.data && me.error?.status === 401) {
			void client.cancelQueries().then(() => client.clear());
		} else if (me.isSuccess && !me.isFetching) router.replace(next);
	}, [client, me.data, me.error, me.isSuccess, me.isFetching, next, router]);
	const queryError = params.get("error");
	const error =
		authErrorMessage(login.error) ??
		(queryError === "google"
			? vi.login.googleError
			: queryError === "google_unverified"
				? vi.login.googleUnverified
				: null);
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-5 px-5 py-6">
			<LoginShapes />
			<h1 className="text-[36px] font-black leading-[1.05]">
				{vi.login.headline}
			</h1>
			{providers.isPending ? (
				<div aria-busy="true" className="h-60 rounded-card bg-sunken" />
			) : providers.isError ? (
				<LoadError
					onRetry={() => {
						void providers.refetch();
					}}
					isRetrying={providers.isFetching}
				/>
			) : (
				<>
					<form
						className="grid gap-4"
						onSubmit={(event) => {
							event.preventDefault();
							if (!login.isPending)
								login.mutate(
									{ email, password },
									{ onSuccess: () => router.replace(next) },
								);
						}}
					>
						<TextField
							label={vi.auth.email}
							type="email"
							required
							maxLength={254}
							autoComplete="username"
							value={email}
							onChange={(event) => setEmail(event.target.value)}
						/>
						<TextField
							label={vi.auth.password}
							type="password"
							required
							maxLength={1024}
							autoComplete="current-password"
							value={password}
							onChange={(event) => setPassword(event.target.value)}
						/>
						{error && <p role="alert">{error}</p>}
						<Button
							type="submit"
							variant="primary"
							size="lg"
							disabled={login.isPending}
						>
							{vi.login.submit}
						</Button>
					</form>
					{providers.data.google && (
						<Link
							href={`/api/v1/auth/google?redirect=${encodeURIComponent(next)}`}
							className="flex h-control-lg items-center justify-center rounded-pill bg-surface font-bold"
						>
							{vi.login.google}
						</Link>
					)}
					<div className="flex justify-between gap-3 text-sm font-bold">
						<Link href="/register" className="flex min-h-11 items-center">
							{vi.login.register}
						</Link>
						<Link
							href="/forgot-password"
							className="flex min-h-11 items-center"
						>
							{vi.login.forgot}
						</Link>
					</div>
					{providers.data.devLogin && (
						<Link
							href={`/dev-login?next=${encodeURIComponent(next)}`}
							className="flex min-h-11 items-center justify-center text-sm text-muted"
						>
							{vi.login.dev}
						</Link>
					)}
				</>
			)}
		</main>
	);
}
export default function LoginPage() {
	return (
		<Suspense
			fallback={
				<main
					aria-busy="true"
					className="mx-auto h-dvh max-w-[430px] bg-sunken"
				/>
			}
		>
			<LoginScreen />
		</Suspense>
	);
}
