"use client";
import type { ButtonHTMLAttributes } from "react";
import { useOnline } from "../../lib/use-online";
export function OnlineButton({
	allowOffline = false,
	disabled,
	...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { allowOffline?: boolean }) {
	const online = useOnline();
	return (
		<button
			{...props}
			disabled={disabled || (!online && !allowOffline)}
			aria-disabled={disabled || (!online && !allowOffline)}
		/>
	);
}
