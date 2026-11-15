"use client";
import { useState } from "react";
import { z } from "zod";
import { authErrorMessage, useDeleteAccount } from "../../lib/auth";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { TextField } from "../ui/TextField";
export function DeleteAccountCard({ email }: { email: string }) {
	const mutation = useDeleteAccount();
	const [confirmation, setConfirmation] = useState("");
	useSessionGuard(mutation.error);
	const details = z
		.object({ groupCount: z.number().int().nonnegative() })
		.safeParse(mutation.error?.details);
	const error =
		mutation.error?.code === "OWNER_REQUIRED" && details.success
			? t(vi.account.ownerRequired, { count: String(details.data.groupCount) })
			: authErrorMessage(mutation.error);
	return (
		<form
			className="grid gap-4 rounded-[28px] bg-debt-soft p-5"
			onSubmit={(event) => {
				event.preventDefault();
				if (confirmation === email && !mutation.isPending)
					mutation.mutate({ email: confirmation });
			}}
		>
			<h2 className="text-xl font-extrabold">{vi.account.delete}</h2>
			<p className="text-sm">{vi.account.deleteHint}</p>
			<TextField
				label={vi.auth.email}
				type="email"
				autoComplete="off"
				required
				maxLength={254}
				value={confirmation}
				onChange={(event) => setConfirmation(event.target.value)}
			/>
			{error && <p role="alert">{error}</p>}
			<Button
				type="submit"
				variant="primary"
				disabled={confirmation !== email || mutation.isPending}
			>
				{vi.account.delete}
			</Button>
		</form>
	);
}
