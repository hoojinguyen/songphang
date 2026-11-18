"use client";
import type { NotificationDto } from "@songphang/contract";
import { NotificationRow } from "../../components/notifications/NotificationRow";
import { Button } from "../../components/ui/Button";
import { LoadError } from "../../components/ui/LoadError";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import {
	useMarkNotificationsRead,
	useNotifications,
} from "../../lib/notifications";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";

export default function NotificationsPage() {
	const notifications = useNotifications();
	const markRead = useMarkNotificationsRead();
	useSessionGuard(notifications.error ?? markRead.error);

	const items =
		notifications.data?.pages.flatMap((page) => page.notifications) ?? [];
	const hasUnread = items.some((item) => !item.read);

	const handleOpen = (notification: NotificationDto) => {
		if (!notification.read) {
			markRead.mutate({ ids: [notification.id] });
		}
	};

	if (notifications.isPending || notifications.error?.status === 401) {
		return (
			<main
				aria-busy="true"
				className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-6"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-24 rounded-card bg-sunken" />
				<div className="h-24 rounded-card bg-sunken" />
			</main>
		);
	}

	if (notifications.isError && !notifications.data) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					isRetrying={notifications.isFetching}
					onRetry={() => {
						void notifications.refetch();
					}}
				/>
			</main>
		);
	}

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-6">
			<ScreenHeader
				title={vi.notifications.title}
				backHref="/"
				backLabel={vi.common.back}
				trailing={
					items.length > 0 ? (
						<Button
							variant="surface"
							disabled={!hasUnread || markRead.isPending}
							onClick={() => markRead.mutate({ all: true })}
							className="h-11 px-3 text-xs"
						>
							{vi.notifications.markAll}
						</Button>
					) : undefined
				}
			/>
			{markRead.isError && <p role="alert">{vi.common.saveError}</p>}
			{items.length === 0 ? (
				<p className="my-auto py-12 text-center text-sm text-muted">
					{vi.notifications.empty}
				</p>
			) : (
				<div className="grid gap-2">
					{items.map((notification) => (
						<NotificationRow
							key={notification.id}
							notification={notification}
							onOpen={handleOpen}
						/>
					))}
				</div>
			)}
			{notifications.hasNextPage && (
				<Button
					variant="surface"
					disabled={notifications.isFetchingNextPage}
					onClick={() => {
						void notifications.fetchNextPage();
					}}
				>
					{vi.notifications.loadMore}
				</Button>
			)}
		</main>
	);
}
