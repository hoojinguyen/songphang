"use client";
import Link from "next/link";
import { useUnreadNotificationCount } from "../../lib/notifications";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";

export function Bell() {
	const unread = useUnreadNotificationCount();
	const count = unread.data?.count ?? 0;
	const label =
		count > 0
			? t(vi.notifications.bellUnreadLabel, { count: String(count) })
			: vi.notifications.title;
	return (
		<Link
			href="/notifications"
			aria-label={label}
			className="relative flex size-12 shrink-0 items-center justify-center rounded-full bg-surface text-ink focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink"
		>
			<Icon name="bell" size={22} />
			{count > 0 && (
				<span
					aria-hidden="true"
					className="absolute -right-0.5 -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-coral px-1 text-[11px] font-extrabold text-on-accent"
				>
					{count > 9 ? "9+" : String(count)}
				</span>
			)}
		</Link>
	);
}
