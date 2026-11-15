"use client";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { Button } from "../../components/ui/Button";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import { TextField } from "../../components/ui/TextField";
import {
	authErrorMessage,
	passwordValidation,
	useResetPassword,
} from "../../lib/auth";
import { vi } from "../../messages/vi";

function ResetScreen() {
	const token = useSearchParams().get("token");
	const mutation = useResetPassword();
	const [password, setPassword] = useState("");
	const [clientError, setClientError] = useState<string | null>(null);
	const invalid = !token || mutation.error?.code === "TOKEN_INVALID";
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-6 px-5 py-6">
			<ScreenHeader
				title={vi.resetPassword.title}
				backHref="/login"
				backLabel={vi.common.back}
			/>
			{mutation.isSuccess ? (
				<>
					<p role="status">{vi.resetPassword.success}</p>
					<Link
						href="/login"
						className="flex h-control-lg items-center justify-center rounded-pill bg-ink font-bold text-surface"
					>
						{vi.login.submit}
					</Link>
				</>
			) : invalid ? (
				<>
					<p role="alert">{vi.resetPassword.invalid}</p>
					<Link
						href="/forgot-password"
						className="flex min-h-11 items-center justify-center rounded-pill bg-surface"
					>
						{vi.resetPassword.newLink}
					</Link>
				</>
			) : (
				<form
					className="grid gap-4"
					onSubmit={(event) => {
						event.preventDefault();
						const invalidPassword = passwordValidation(password);
						setClientError(invalidPassword);
						if (!invalidPassword && !mutation.isPending)
							mutation.mutate({ token, password });
					}}
				>
					<TextField
						label={vi.resetPassword.field}
						type="password"
						required
						maxLength={1024}
						autoComplete="new-password"
						value={password}
						onChange={(event) => setPassword(event.target.value)}
					/>
					{(clientError || mutation.isError) && (
						<p role="alert">
							{clientError ?? authErrorMessage(mutation.error)}
						</p>
					)}
					<Button
						type="submit"
						variant="primary"
						size="lg"
						disabled={mutation.isPending}
					>
						{vi.resetPassword.submit}
					</Button>
				</form>
			)}
		</main>
	);
}
export default function ResetPasswordPage() {
	return (
		<Suspense
			fallback={
				<main
					aria-busy="true"
					className="mx-auto h-dvh max-w-[430px] bg-sunken"
				/>
			}
		>
			<ResetScreen />
		</Suspense>
	);
}
