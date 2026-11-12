import Link from "next/link";
import type { ReactNode } from "react";
import { Icon } from "./Icon";
export function ScreenHeader({
	title,
	subtitle,
	backHref,
	backLabel,
	trailing,
}: {
	title: string;
	subtitle?: string;
	backHref: string;
	backLabel: string;
	trailing?: ReactNode;
}) {
	return (
		<header className="flex items-center gap-3">
			<Link
				href={backHref}
				aria-label={backLabel}
				className="flex size-12 shrink-0 items-center justify-center rounded-[18px] bg-surface"
			>
				<Icon name="back" size={24} />
			</Link>
			<div className="min-w-0 flex-1">
				<h1 className="break-words text-[18px] font-extrabold">{title}</h1>
				{subtitle && <p className="text-xs text-muted">{subtitle}</p>}
			</div>
			{trailing}
		</header>
	);
}
