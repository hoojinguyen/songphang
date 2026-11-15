"use client";
import { authErrorMessage, useResendVerification } from "../../lib/auth";
import { useMe } from "../../lib/session";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "./Button";
export function VerifyEmailBanner() {
	const me = useMe();
	const resend = useResendVerification();
	useSessionGuard(resend.error);
	if (me.data?.emailVerified !== false) return null;
	return (
		<div className="grid gap-3 rounded-[30px] bg-accent p-5 text-sm font-bold">
			<p>{vi.verify.banner}</p>
			<Button
				variant="surface"
				onClick={() => resend.mutate()}
				disabled={resend.isPending}
			>
				{vi.verify.resend}
			</Button>
			{resend.isSuccess && <p role="status">{vi.verify.resent}</p>}
			{resend.isError && <p role="alert">{authErrorMessage(resend.error)}</p>}
		</div>
	);
}
