"use client";
import Link from "next/link";
import { useFeatures } from "../../lib/features";
import { useOnline } from "../../lib/use-online";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { CameraButton } from "./CameraButton";
export function EntryBar({
	groupId,
	readOnly = false,
}: {
	groupId: string;
	readOnly?: boolean;
}) {
	const online = useOnline();
	const features = useFeatures();
	if (!online)
		return (
			<div className="fixed bottom-0 left-1/2 w-full max-w-[430px] -translate-x-1/2 bg-bg px-5 pb-5 pt-3">
				<div
					aria-disabled="true"
					className="flex h-16 items-center justify-center rounded-[32px] bg-sunken text-sm text-muted"
				>
					{vi.offline.entry}
				</div>
			</div>
		);
	if (readOnly)
		return (
			<div className="fixed bottom-0 left-1/2 w-full max-w-[430px] -translate-x-1/2 bg-bg px-5 pb-5 pt-3">
				<div className="flex h-16 items-center justify-center rounded-[32px] bg-sunken text-sm font-semibold text-muted">
					{vi.members.roleViewer}
				</div>
			</div>
		);
	return (
		<div className="fixed bottom-0 left-1/2 flex w-full max-w-[430px] -translate-x-1/2 gap-3 bg-bg px-5 pb-5 pt-3">
			<Link
				href={`/g/${groupId}/tx/new?form`}
				className="flex h-16 w-[84px] shrink-0 flex-col items-center justify-center rounded-[26px] bg-accent text-xs font-extrabold text-on-accent"
			>
				<Icon name="plus" size={24} />
				{vi.feed.manualEntry}
			</Link>
			{features.data?.receiptReading && <CameraButton groupId={groupId} />}
			<Link
				href={`/g/${groupId}/tx/new`}
				className="flex h-16 min-w-0 flex-1 items-center rounded-[32px] bg-surface px-4 text-[15px] text-muted"
			>
				{vi.feed.entryPlaceholder}
			</Link>
		</div>
	);
}
