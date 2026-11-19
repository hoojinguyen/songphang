"use client";
import { vi } from "../../messages/vi";
import { ScreenHeader } from "../ui/ScreenHeader";
import { ReceiptPhoto } from "./ReceiptScanStates";

export function ReceiptDetailsFields({
	groupId,
	imageUrl,
	description,
	onDescriptionChange,
	occurredOn,
	onOccurredOnChange,
}: {
	groupId: string;
	imageUrl: string;
	description: string;
	onDescriptionChange: (value: string) => void;
	occurredOn: string;
	onOccurredOnChange: (value: string) => void;
}) {
	return (
		<>
			<div>
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.cancel}
					backIcon="close"
				/>
				<p className="mt-1 text-xs font-semibold text-muted">
					{vi.receipts.aiNote}
				</p>
			</div>

			<div className="flex items-start gap-3">
				<ReceiptPhoto imageUrl={imageUrl} size="small" />
				<div className="grid min-w-0 flex-1 gap-2">
					<input
						aria-label={vi.receipts.descriptionLabel}
						maxLength={200}
						value={description}
						onChange={(event) => onDescriptionChange(event.target.value)}
						className="h-11 rounded-[18px] bg-surface px-3 text-base font-extrabold text-ink"
					/>
					<input
						aria-label={vi.receipts.dateLabel}
						type="date"
						value={occurredOn}
						onChange={(event) => onOccurredOnChange(event.target.value)}
						className="h-11 rounded-[18px] bg-surface px-3 text-base text-ink"
					/>
				</div>
			</div>
		</>
	);
}
