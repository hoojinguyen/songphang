"use client";
import Link from "next/link";
import { useState } from "react";
import { Button } from "../../components/ui/Button";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import { TextField } from "../../components/ui/TextField";
import {
	authErrorMessage,
	passwordValidation,
	useRegister,
} from "../../lib/auth";
import { vi } from "../../messages/vi";
export default function RegisterPage() {
	const mutation = useRegister();
	const [name, setName] = useState("");
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [clientError, setClientError] = useState<string | null>(null);
	const error = clientError ?? authErrorMessage(mutation.error);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-6 px-5 py-6">
			<ScreenHeader
				title={vi.register.title}
				backHref="/login"
				backLabel={vi.common.back}
			/>
			{mutation.isSuccess ? (
				<>
					<h2 className="text-[28px] font-black">
						{vi.register.submittedTitle}
					</h2>
					<p>{vi.register.submittedBody}</p>
					<Link
						href="/login"
						className="flex h-control-lg items-center justify-center rounded-pill bg-ink font-bold text-surface"
					>
						{vi.login.submit}
					</Link>
				</>
			) : (
				<form
					className="grid gap-4"
					onSubmit={(event) => {
						event.preventDefault();
						const invalid =
							name.trim().length > 50
								? vi.register.nameTooLong
								: passwordValidation(password);
						setClientError(invalid);
						if (!invalid && !mutation.isPending)
							mutation.mutate({ name: name.trim(), email, password });
					}}
				>
					<TextField
						label={vi.register.name}
						required
						maxLength={51}
						autoComplete="nickname"
						value={name}
						onChange={(event) => setName(event.target.value)}
					/>
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
						autoComplete="new-password"
						hint={vi.register.passwordHint}
						value={password}
						onChange={(event) => setPassword(event.target.value)}
					/>
					{error && <p role="alert">{error}</p>}
					<Button
						type="submit"
						variant="primary"
						size="lg"
						disabled={mutation.isPending}
					>
						{vi.register.title}
					</Button>
					<Link
						href="/login"
						className="flex min-h-11 items-center justify-center text-sm font-bold"
					>
						{vi.register.login}
					</Link>
				</form>
			)}
		</main>
	);
}
