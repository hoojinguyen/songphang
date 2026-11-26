"use client";
import type { RecurringFrequency, RecurringMode } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
import { Switch } from "../ui/Switch";

const FREQUENCIES: Array<{ value: RecurringFrequency; label: string }> = [
	{ value: "weekly", label: vi.recurring.freqWeekly },
	{ value: "monthly", label: vi.recurring.freqMonthly },
	{ value: "quarterly", label: vi.recurring.freqQuarterly },
	{ value: "yearly", label: vi.recurring.freqYearly },
];

export function RecurringInlineCard({
	enabled,
	onToggle,
	mode,
	onModeChange,
	frequency,
	onFrequencyChange,
	canVariable,
}: {
	enabled: boolean;
	onToggle: (next: boolean) => void;
	mode: RecurringMode;
	onModeChange: (next: RecurringMode) => void;
	frequency: RecurringFrequency;
	onFrequencyChange: (next: RecurringFrequency) => void;
	canVariable: boolean;
}) {
	const activeMode = canVariable ? mode : "fixed";

	return (
		<section className="grid gap-3 rounded-[26px] bg-surface p-4">
			<div className="flex items-center justify-between gap-3">
				<span className="text-sm font-extrabold text-ink">
					{vi.recurring.toggleLabel}
				</span>
				<Switch
					checked={enabled}
					onChange={onToggle}
					label={vi.recurring.toggleLabel}
				/>
			</div>

			{enabled && (
				<div className="grid gap-3 border-t border-border-subtle pt-3">
					<div className="grid gap-1.5">
						<p className="text-xs font-bold text-muted">
							{vi.recurring.modeLabel}
						</p>
						<div className="grid gap-1.5">
							<OnlineButton
								type="button"
								allowOffline
								aria-pressed={activeMode === "fixed"}
								onClick={() => onModeChange("fixed")}
								className={`min-h-11 rounded-[16px] px-3 text-left text-xs font-bold ${
									activeMode === "fixed"
										? "bg-ink text-on-ink"
										: "bg-sunken text-ink"
								}`}
							>
								{vi.recurring.modeFixedDesc}
							</OnlineButton>
							<OnlineButton
								type="button"
								allowOffline
								disabled={!canVariable}
								aria-pressed={activeMode === "variable"}
								onClick={() => onModeChange("variable")}
								className={`min-h-11 rounded-[16px] px-3 text-left text-xs font-bold disabled:opacity-40 ${
									activeMode === "variable"
										? "bg-ink text-on-ink"
										: "bg-sunken text-ink"
								}`}
							>
								{vi.recurring.modeVariableDesc}
							</OnlineButton>
						</div>
					</div>

					<div className="grid gap-1.5">
						<p className="text-xs font-bold text-muted">
							{vi.recurring.frequencyLabel}
						</p>
						<div className="flex flex-wrap gap-1.5">
							{FREQUENCIES.map((option) => (
								<OnlineButton
									key={option.value}
									type="button"
									allowOffline
									aria-pressed={frequency === option.value}
									onClick={() => onFrequencyChange(option.value)}
									className={`min-h-11 rounded-pill px-3 text-xs font-extrabold ${
										frequency === option.value
											? "bg-ink text-on-ink"
											: "bg-sunken text-ink"
									}`}
								>
									{option.label}
								</OnlineButton>
							))}
						</div>
					</div>
				</div>
			)}
		</section>
	);
}
