"use client";
import { vi } from "../../messages/vi";

export type StatsPeriod = "all" | "thisMonth" | "lastMonth" | "custom";

export function PeriodChips({
	period,
	from,
	to,
	onPeriod,
	onCustomFrom,
	onCustomTo,
}: {
	period: StatsPeriod;
	from: string;
	to: string;
	onPeriod: (period: StatsPeriod) => void;
	onCustomFrom: (value: string) => void;
	onCustomTo: (value: string) => void;
}) {
	const options: Array<{ value: StatsPeriod; label: string }> = [
		{ value: "all", label: vi.stats.all },
		{ value: "thisMonth", label: vi.stats.thisMonth },
		{ value: "lastMonth", label: vi.stats.lastMonth },
		{ value: "custom", label: vi.stats.custom },
	];
	return (
		<div className="grid gap-3">
			<div className="flex flex-wrap gap-2">
				{options.map((option) => (
					<button
						key={option.value}
						type="button"
						aria-pressed={period === option.value}
						onClick={() => onPeriod(option.value)}
						className={`min-h-11 rounded-pill px-4 text-xs font-bold ${
							period === option.value
								? "bg-ink text-surface"
								: "bg-surface text-ink"
						}`}
					>
						{option.label}
					</button>
				))}
			</div>
			{period === "custom" && (
				<div className="grid grid-cols-2 gap-2">
					<label className="grid gap-1 text-xs font-semibold text-muted">
						{vi.filter.fromDate}
						<input
							type="date"
							value={from}
							onChange={(event) => onCustomFrom(event.target.value)}
							className="min-h-11 rounded-[20px] bg-surface px-3 text-sm font-bold text-ink"
						/>
					</label>
					<label className="grid gap-1 text-xs font-semibold text-muted">
						{vi.filter.toDate}
						<input
							type="date"
							value={to}
							onChange={(event) => onCustomTo(event.target.value)}
							className="min-h-11 rounded-[20px] bg-surface px-3 text-sm font-bold text-ink"
						/>
					</label>
				</div>
			)}
		</div>
	);
}
