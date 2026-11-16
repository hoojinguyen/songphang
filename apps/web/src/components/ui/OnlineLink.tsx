"use client";
import Link from "next/link";
import type { ComponentProps } from "react";
import { useOnline } from "../../lib/use-online";
import { vi } from "../../messages/vi";
export function OnlineLink(props: ComponentProps<typeof Link>) {
	const online = useOnline();
	return online ? (
		<Link {...props} />
	) : (
		<div>
			<button
				type="button"
				disabled
				aria-disabled="true"
				className={props.className}
			>
				{props.children}
			</button>
			<p className="text-xs text-muted">{vi.offline.writeDisabled}</p>
		</div>
	);
}
