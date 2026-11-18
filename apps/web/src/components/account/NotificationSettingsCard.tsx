"use client";
import {
	useNotificationSettings,
	useUpdateNotificationSettings,
} from "../../lib/notifications";
import { vi } from "../../messages/vi";
import { LoadError } from "../ui/LoadError";
import { Switch } from "../ui/Switch";

export function NotificationSettingsCard() {
	const settings = useNotificationSettings();
	const update = useUpdateNotificationSettings();

	if (settings.isPending) {
		return <div aria-busy="true" className="h-32 rounded-[30px] bg-sunken" />;
	}
	if (settings.isError && !settings.data) {
		return (
			<LoadError
				isRetrying={settings.isFetching}
				onRetry={() => {
					void settings.refetch();
				}}
			/>
		);
	}
	return (
		<section className="grid gap-4 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.notifications.emailSettingsTitle}</h2>
			<div className="flex items-center justify-between gap-3">
				<span className="text-sm font-semibold text-ink">
					{vi.notifications.emailImmediate}
				</span>
				<Switch
					checked={settings.data.emailImmediate}
					disabled={update.isPending}
					label={vi.notifications.emailImmediate}
					onChange={(emailImmediate) => update.mutate({ emailImmediate })}
				/>
			</div>
			<div className="flex items-center justify-between gap-3">
				<span className="text-sm font-semibold text-ink">
					{vi.notifications.emailDigest}
				</span>
				<Switch
					checked={settings.data.emailDigest}
					disabled={update.isPending}
					label={vi.notifications.emailDigest}
					onChange={(emailDigest) => update.mutate({ emailDigest })}
				/>
			</div>
			{update.isError && <p role="alert">{vi.common.saveError}</p>}
		</section>
	);
}
