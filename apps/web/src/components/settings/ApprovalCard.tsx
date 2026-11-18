"use client";
import type { GroupDto } from "@songphang/contract";
import { useState } from "react";
import { useUpdateGroup } from "../../lib/groups";
import { formatAmount, parseAmountInput } from "../../lib/money";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { AmountField } from "../expense-form/AmountField";
import { Button } from "../ui/Button";
import { Switch } from "../ui/Switch";

export function ApprovalCard({ group }: { group: GroupDto }) {
	const update = useUpdateGroup(group.id);
	useSessionGuard(update.error);
	const [draft, setDraft] = useState<{
		enabled: boolean;
		amountText: string;
	} | null>(null);

	const enabled = draft?.enabled ?? group.approvalThreshold !== null;
	const amountText =
		draft?.amountText ??
		(group.approvalThreshold !== null
			? formatAmount(group.approvalThreshold)
			: "");
	const parsed = parseAmountInput(amountText);
	const valid = parsed !== null && parsed >= 1 && parsed <= 999_999_999_999;
	const unchanged =
		group.approvalThreshold !== null && parsed === group.approvalThreshold;

	const handleToggle = (next: boolean) => {
		if (!next) {
			if (group.approvalThreshold !== null) {
				update.mutate(
					{ approvalThreshold: null },
					{ onSuccess: () => setDraft(null) },
				);
			} else {
				setDraft(null);
			}
			return;
		}
		setDraft({ enabled: true, amountText });
	};

	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<div className="flex items-center justify-between gap-3">
				<h2 className="font-extrabold">{vi.approval.settingsTitle}</h2>
				<Switch
					checked={enabled}
					onChange={handleToggle}
					disabled={update.isPending}
					label={vi.approval.settingsTitle}
				/>
			</div>
			{enabled && (
				<>
					<div className="grid gap-1.5">
						<span className="text-[13px] font-semibold text-muted">
							{vi.approval.thresholdLabel}
						</span>
						<AmountField
							value={amountText}
							onChange={(next) => setDraft({ enabled: true, amountText: next })}
							autoFocus={false}
							label={vi.approval.thresholdLabel}
						/>
					</div>
					<p className="text-xs text-muted">{vi.approval.settingsHint}</p>
					{update.isError && (
						<p role="alert" className="text-xs font-semibold text-debt">
							{update.error.status === 403
								? vi.common.forbidden
								: vi.common.saveError}
						</p>
					)}
					<Button
						variant="primary"
						disabled={update.isPending || !valid || unchanged}
						onClick={() => {
							if (!valid) return;
							update.mutate(
								{ approvalThreshold: parsed },
								{ onSuccess: () => setDraft(null) },
							);
						}}
					>
						{vi.fund.saveButton}
					</Button>
				</>
			)}
		</section>
	);
}
