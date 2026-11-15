"use client";
import { useState } from "react";
import { Button } from "../../components/ui/Button";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import { TextField } from "../../components/ui/TextField";
import { authErrorMessage, useForgotPassword } from "../../lib/auth";
import { vi } from "../../messages/vi";
export default function ForgotPasswordPage() {
	const [email, setEmail] = useState("");
	const mutation = useForgotPassword();
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-6 px-5 py-6">
			<ScreenHeader
				title={vi.forgotPassword.title}
				backHref="/login"
				backLabel={vi.common.back}
			/>
			{mutation.isSuccess ? (
				<p role="status">{vi.forgotPassword.submitted}</p>
			) : (
				<form
					className="grid gap-4"
					onSubmit={(event) => {
						event.preventDefault();
						if (!mutation.isPending) mutation.mutate({ email });
					}}
				>
					<p>{vi.forgotPassword.hint}</p>
					<TextField
						label={vi.auth.email}
						type="email"
						required
						maxLength={254}
						autoComplete="email"
						value={email}
						onChange={(event) => setEmail(event.target.value)}
					/>
					{mutation.isError && (
						<p role="alert">{authErrorMessage(mutation.error)}</p>
					)}
					<Button
						type="submit"
						variant="primary"
						size="lg"
						disabled={mutation.isPending}
					>
						{vi.forgotPassword.submit}
					</Button>
				</form>
			)}
		</main>
	);
}
