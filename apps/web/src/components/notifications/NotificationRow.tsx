"use client";
import type { NotificationDto } from "@songphang/contract";
import { formatVietnamDateTime } from "@songphang/core";
import Link from "next/link";
import { notificationText } from "../../lib/notification-text";

export function NotificationRow({
	notification,
	onOpen,
}: {
	notification: NotificationDto;
	onOpen: (notification: NotificationDto) => void;
}) {
	const { text, href } = notificationText(notification);
	const groupName =
		typeof notification.payload.groupName === "string"
			? notification.payload.groupName
			: "";
	return (
		<Link
			href={href}
			onClick={() => onOpen(notification)}
			className={`grid gap-1 rounded-[24px] px-4 py-3.5 transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink ${
				notification.read ? "bg-surface" : "bg-sunken"
			}`}
		>
			<p className="break-words text-sm font-semibold text-ink">{text}</p>
			<p className="text-xs text-muted">
				{groupName ? `${groupName} · ` : ""}
				{formatVietnamDateTime(new Date(notification.createdAt))}
			</p>
		</Link>
	);
}
