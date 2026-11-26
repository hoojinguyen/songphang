"use client";
import type { ExtrasAllocation, ItemsSplitExtra } from "@songphang/contract";
import { formatAmount, formatMoney, parseAmountInput } from "../../lib/money";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { OnlineButton } from "../ui/OnlineButton";
import { SegmentedControl } from "../ui/SegmentedControl";

export type EditableManualExtra = {
	id: string;
	kind: ItemsSplitExtra["kind"];
	label: string;
	mode: "percent" | "amount";
	ratePercentText: string;
	amountText: string;
};

const EXTRA_KINDS: ItemsSplitExtra["kind"][] = [
	"tax",
	"service",
	"shipping",
	"discount",
	"other",
];

const KIND_LABELS: Record<ItemsSplitExtra["kind"], string> = {
	tax: vi.extras.kindTax,
	service: vi.extras.kindService,
	shipping: vi.extras.kindShipping,
	discount: vi.extras.kindDiscount,
	other: vi.extras.kindOther,
};

const PERCENT_SUPPORTED_KINDS = new Set<ItemsSplitExtra["kind"]>([
	"tax",
	"service",
	"discount",
]);

const DEFAULT_RATE_BY_KIND: Partial<Record<ItemsSplitExtra["kind"], string>> = {
	tax: "8",
	service: "5",
	discount: "10",
};

export function ManualExtrasCard({
	extras,
	extrasAllocation,
	resolvedExtras,
	computedAmount,
	previewCurrent,
	onChangeAllocation,
	onTogglePreset,
	onAddExtra,
	onChangeExtra,
	onRemoveExtra,
}: {
	extras: EditableManualExtra[];
	extrasAllocation: ExtrasAllocation;
	resolvedExtras: readonly ItemsSplitExtra[] | undefined;
	computedAmount: number | undefined;
	previewCurrent: boolean;
	onChangeAllocation: (next: ExtrasAllocation) => void;
	onTogglePreset: (kind: "tax" | "service", ratePercentText: string) => void;
	onAddExtra: (kind: ItemsSplitExtra["kind"]) => void;
	onChangeExtra: (
		id: string,
		patch: Partial<
			Pick<
				EditableManualExtra,
				"kind" | "label" | "mode" | "ratePercentText" | "amountText"
			>
		>,
	) => void;
	onRemoveExtra: (id: string) => void;
}) {
	const hasPreset = (kind: "tax" | "service", rate: string) =>
		extras.some(
			(extra) =>
				extra.kind === kind &&
				extra.mode === "percent" &&
				extra.ratePercentText === rate,
		);
	const full = extras.length >= 6;

	return (
		<div className="grid gap-2.5">
			<div className="flex flex-wrap gap-1.5">
				<PresetChip
					label={vi.extras.chipVat8}
					active={hasPreset("tax", "8")}
					disabled={!hasPreset("tax", "8") && full}
					onClick={() => onTogglePreset("tax", "8")}
				/>
				<PresetChip
					label={vi.extras.chipVat10}
					active={hasPreset("tax", "10")}
					disabled={!hasPreset("tax", "10") && full}
					onClick={() => onTogglePreset("tax", "10")}
				/>
				<PresetChip
					label={vi.extras.chipService5}
					active={hasPreset("service", "5")}
					disabled={!hasPreset("service", "5") && full}
					onClick={() => onTogglePreset("service", "5")}
				/>
				<AddChip
					label={vi.extras.chipShipping}
					disabled={full}
					onClick={() => onAddExtra("shipping")}
				/>
				<AddChip
					label={vi.extras.chipDiscount}
					disabled={full}
					onClick={() => onAddExtra("discount")}
				/>
				<AddChip
					label={vi.extras.chipOther}
					disabled={full}
					onClick={() => onAddExtra("other")}
				/>
			</div>

			{extras.length > 0 && (
				<section className="grid gap-2.5 rounded-[26px] bg-surface p-3">
					<div className="flex flex-wrap items-center justify-between gap-2">
						<h2 className="text-sm font-extrabold text-ink">
							{vi.extras.cardTitle}
						</h2>
						<div className="w-44">
							<SegmentedControl
								label={vi.extras.cardTitle}
								allowOffline
								value={extrasAllocation}
								onChange={(value) => {
									if (value === "equal" || value === "proportional") {
										onChangeAllocation(value);
									}
								}}
								options={[
									{ value: "equal", label: vi.extras.allocEqual },
									{ value: "proportional", label: vi.extras.allocProportional },
								]}
							/>
						</div>
					</div>

					{full && (
						<p role="status" className="text-xs font-semibold text-muted">
							{vi.extras.maxExtras}
						</p>
					)}

					<div className="grid gap-2">
						{extras.map((extra, index) => {
							const resolved = previewCurrent
								? resolvedExtras?.[index]
								: undefined;
							const parsedManual = parseAmountInput(extra.amountText);
							const displayAmount =
								extra.mode === "percent"
									? resolved?.amount
									: (resolved?.amount ?? parsedManual ?? undefined);
							const supportsPercent = PERCENT_SUPPORTED_KINDS.has(extra.kind);

							return (
								<div
									key={extra.id}
									className="grid gap-1.5 rounded-[20px] bg-bg p-2.5"
								>
									<div className="flex items-center gap-1.5">
										<select
											aria-label={KIND_LABELS[extra.kind]}
											value={extra.kind}
											onChange={(event) => {
												const nextKind = EXTRA_KINDS.find(
													(kind) => kind === event.target.value,
												);
												if (!nextKind) return;
												onChangeExtra(extra.id, {
													kind: nextKind,
													...(PERCENT_SUPPORTED_KINDS.has(nextKind)
														? {}
														: { mode: "amount", ratePercentText: "" }),
												});
											}}
											className="min-h-11 rounded-[14px] bg-surface px-2 text-xs font-bold text-ink"
										>
											{EXTRA_KINDS.map((kind) => (
												<option key={kind} value={kind}>
													{KIND_LABELS[kind]}
												</option>
											))}
										</select>
										<input
											aria-label={vi.receipts.extraLabelLabel}
											maxLength={40}
											value={extra.label}
											onChange={(event) =>
												onChangeExtra(extra.id, { label: event.target.value })
											}
											placeholder={KIND_LABELS[extra.kind]}
											className="min-h-11 min-w-0 flex-1 rounded-[14px] bg-surface px-2.5 text-sm font-bold text-ink"
										/>
										<OnlineButton
											type="button"
											allowOffline
											aria-label={vi.extras.remove}
											onClick={() => onRemoveExtra(extra.id)}
											className="flex size-11 shrink-0 items-center justify-center rounded-pill bg-surface text-muted hover:text-ink"
										>
											<Icon name="close" size={16} />
										</OnlineButton>
									</div>

									<div className="flex items-center gap-2">
										{supportsPercent && (
											<div className="flex rounded-[14px] bg-sunken p-0.5">
												<OnlineButton
													type="button"
													allowOffline
													aria-pressed={extra.mode === "percent"}
													aria-label={vi.extras.modePercent}
													onClick={() =>
														onChangeExtra(extra.id, {
															mode: "percent",
															ratePercentText:
																extra.ratePercentText ||
																DEFAULT_RATE_BY_KIND[extra.kind] ||
																"8",
														})
													}
													className={`min-h-11 rounded-[12px] px-2.5 text-xs font-extrabold ${
														extra.mode === "percent"
															? "bg-ink text-on-ink"
															: "text-ink"
													}`}
												>
													%
												</OnlineButton>
												<OnlineButton
													type="button"
													allowOffline
													aria-pressed={extra.mode === "amount"}
													aria-label={vi.extras.modeAmount}
													onClick={() =>
														onChangeExtra(extra.id, {
															mode: "amount",
															ratePercentText: "",
															amountText:
																extra.amountText ||
																(resolved ? formatAmount(resolved.amount) : ""),
														})
													}
													className={`min-h-11 rounded-[12px] px-2.5 text-xs font-extrabold ${
														extra.mode === "amount"
															? "bg-ink text-on-ink"
															: "text-ink"
													}`}
												>
													{vi.common.currency}
												</OnlineButton>
											</div>
										)}

										{extra.mode === "percent" ? (
											<label className="flex min-h-11 w-24 items-center gap-1 rounded-[14px] bg-surface px-2.5">
												<input
													aria-label={vi.extras.percentLabel}
													inputMode="decimal"
													value={extra.ratePercentText}
													onChange={(event) => {
														const normalized = event.target.value.replace(
															",",
															".",
														);
														if (/^\d{0,2}(\.\d{0,2})?$/.test(normalized)) {
															onChangeExtra(extra.id, {
																ratePercentText: normalized,
																amountText: "",
															});
														}
													}}
													placeholder="8"
													className="min-w-0 flex-1 bg-transparent text-right tabular-nums text-sm font-black text-ink outline-none"
												/>
												<span className="text-xs font-bold text-muted">%</span>
											</label>
										) : (
											<label className="flex min-h-11 min-w-0 flex-1 items-center gap-1 rounded-[14px] bg-surface px-2.5">
												<input
													aria-label={vi.extras.amountLabel}
													inputMode="numeric"
													value={extra.amountText}
													onChange={(event) => {
														const raw = event.target.value.replace(
															/[^0-9]/g,
															"",
														);
														if (!raw) {
															onChangeExtra(extra.id, {
																mode: "amount",
																ratePercentText: "",
																amountText: "",
															});
															return;
														}
														const parsed = parseAmountInput(raw);
														if (parsed !== null) {
															onChangeExtra(extra.id, {
																mode: "amount",
																ratePercentText: "",
																amountText: formatAmount(parsed),
															});
														}
													}}
													placeholder="0"
													className="min-w-0 flex-1 bg-transparent text-right tabular-nums text-sm font-black text-ink outline-none"
												/>
												<span className="text-xs font-bold text-muted">
													{vi.common.currency}
												</span>
											</label>
										)}

										<span
											className={`ml-auto shrink-0 tabular-nums text-sm font-extrabold ${
												extra.kind === "discount" ? "text-credit" : "text-ink"
											}`}
										>
											{displayAmount !== undefined
												? `${extra.kind === "discount" ? "−" : "+"}${formatMoney(displayAmount)}`
												: vi.common.pendingValue}
										</span>
									</div>
								</div>
							);
						})}
					</div>

					<div className="flex items-center justify-between gap-2 rounded-[18px] bg-phrase-amount px-3.5 py-2.5 text-ink">
						<span className="text-xs font-extrabold">
							{vi.extras.totalPayment}
						</span>
						<span className="tabular-nums text-base font-black">
							{previewCurrent && computedAmount !== undefined
								? formatMoney(computedAmount)
								: vi.common.pendingValue}
						</span>
					</div>
				</section>
			)}
		</div>
	);
}

function PresetChip({
	label,
	active,
	disabled,
	onClick,
}: {
	label: string;
	active: boolean;
	disabled: boolean;
	onClick: () => void;
}) {
	return (
		<OnlineButton
			type="button"
			allowOffline
			aria-pressed={active}
			disabled={disabled}
			onClick={onClick}
			className={`min-h-11 rounded-pill px-3 text-xs font-extrabold transition-colors disabled:opacity-40 ${
				active ? "bg-ink text-on-ink" : "bg-surface text-ink"
			}`}
		>
			{label}
		</OnlineButton>
	);
}

function AddChip({
	label,
	disabled,
	onClick,
}: {
	label: string;
	disabled: boolean;
	onClick: () => void;
}) {
	return (
		<OnlineButton
			type="button"
			allowOffline
			disabled={disabled}
			onClick={onClick}
			className="min-h-11 rounded-pill bg-surface px-3 text-xs font-extrabold text-ink disabled:opacity-40"
		>
			{label}
		</OnlineButton>
	);
}
