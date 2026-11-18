import type { NotificationDto } from "@songphang/contract";
import { formatNotificationText } from "@songphang/core";

export function notificationText(dto: NotificationDto): {
	text: string;
	href: string;
} {
	return formatNotificationText(dto);
}
