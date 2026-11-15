"use client";
import { useState } from "react";
import {
	authErrorMessage,
	passwordValidation,
	useChangePassword,
} from "../../lib/auth";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { TextField } from "../ui/TextField";
export function ChangePasswordCard() {
	const mutation = useChangePassword();
	const [currentPassword, setCurrentPassword] = useState("");
	const [newPassword, setNewPassword] = useState("");
	const [revokeOtherSessions, setRevokeOtherSessions] = useState(false);
	const [clientError, setClientError] = useState<string | null>(null);
	const error =
		clientError ??
		(mutation.error?.code === "INVALID_CREDENTIALS"
			? vi.account.wrongPassword
			: authErrorMessage(mutation.error));
	return (
		<form
			className="grid gap-4 rounded-[30px] bg-surface p-5"
			onSubmit={(event) => {
				event.preventDefault();
				const invalid = passwordValidation(newPassword);
				setClientError(invalid);
				if (!invalid && !mutation.isPending)
					mutation.mutate(
						{ currentPassword, newPassword, revokeOtherSessions },
						{
							onSuccess: () => {
								setCurrentPassword("");
								setNewPassword("");
							},
						},
					);
			}}
		>
			<h2 className="text-xl font-extrabold">{vi.account.changePassword}</h2>
			<TextField
				label={vi.account.currentPassword}
				type="password"
				autoComplete="current-password"
				required
				maxLength={1024}
				value={currentPassword}
				onChange={(event) => setCurrentPassword(event.target.value)}
				className="bg-sunken"
			/>
			<TextField
				label={vi.account.newPassword}
				type="password"
				autoComplete="new-password"
				required
				maxLength={1024}
				value={newPassword}
				onChange={(event) => setNewPassword(event.target.value)}
				className="bg-sunken"
			/>
			<label className="flex min-h-11 items-center gap-3 text-sm">
				<input
					type="checkbox"
					checked={revokeOtherSessions}
					onChange={(event) => setRevokeOtherSessions(event.target.checked)}
					className="size-5"
				/>
				{vi.account.revokeOthers}
			</label>
			{error && <p role="alert">{error}</p>}
			{mutation.isSuccess && <p role="status">{vi.account.passwordChanged}</p>}
			<Button type="submit" variant="primary" disabled={mutation.isPending}>
				{vi.account.savePassword}
			</Button>
		</form>
	);
}
