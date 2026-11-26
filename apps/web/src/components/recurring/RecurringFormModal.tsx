"use client";
import {
	type CategoryDto,
	CreateRecurringExpenseRequest,
	type MemberDto,
	type RecurringExpenseDto,
	type RecurringFrequency,
	type RecurringMode,
	UpdateRecurringExpenseRequest,
} from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import { formatAmount, parseAmountInput } from "../../lib/money";
import {
	useCreateRecurringExpense,
	useUpdateRecurringExpense,
} from "../../lib/recurring-expenses";
import { vi } from "../../messages/vi";
import { CategoryPicker } from "../expense-form/CategoryPicker";
import { SplitMemberRow } from "../expense-form/SplitMemberRow";
import {
	type SplitMethod,
	useSplitState,
} from "../expense-form/use-split-state";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";

const FREQUENCIES: Array<{ value: RecurringFrequency; label: string }> = [
	{ value: "weekly", label: vi.recurring.freqWeekly },
	{ value: "monthly", label: vi.recurring.freqMonthly },
	{ value: "quarterly", label: vi.recurring.freqQuarterly },
	{ value: "yearly", label: vi.recurring.freqYearly },
];

const SPLIT_METHODS: Array<{ value: SplitMethod; label: string }> = [
	{ value: "equal", label: vi.split.modeEqual },
	{ value: "shares", label: vi.split.modeShares },
	{ value: "percent", label: vi.split.modePercent },
	{ value: "exact", label: vi.split.modeExact },
];

function weekdayLabel(isoDay: number): string {
	// 2024-01-01 is Monday (ISO day 1).
	const date = new Date(Date.UTC(2024, 0, isoDay));
	return new Intl.DateTimeFormat("vi-VN", {
		weekday: "long",
		timeZone: "UTC",
	}).format(date);
}

export function RecurringFormModal({
	open,
	groupId,
	members,
	categories,
	myMemberId,
	editing,
	onClose,
}: {
	open: boolean;
	groupId: string;
	members: MemberDto[];
	categories: CategoryDto[];
	myMemberId: string | null;
	editing: RecurringExpenseDto | null;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) dialog.showModal();
		else if (!open && dialog.open) dialog.close();
	}, [open]);

	if (!open) return <dialog ref={dialogRef} className="hidden" />;

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto max-h-[90dvh] w-[calc(100%-24px)] max-w-[430px] overflow-hidden rounded-[30px] bg-bg p-0 text-ink backdrop:bg-ink/45"
		>
			<RecurringFormBody
				key={editing?.id ?? "new"}
				titleId={titleId}
				groupId={groupId}
				members={members}
				categories={categories}
				myMemberId={myMemberId}
				editing={editing}
				onClose={onClose}
			/>
		</dialog>
	);
}

function RecurringFormBody({
	titleId,
	groupId,
	members,
	categories,
	myMemberId,
	editing,
	onClose,
}: {
	titleId: string;
	groupId: string;
	members: MemberDto[];
	categories: CategoryDto[];
	myMemberId: string | null;
	editing: RecurringExpenseDto | null;
	onClose: () => void;
}) {
	const activePeople = members.filter(
		(member) => member.kind === "person" && member.active,
	);
	const activeFund = members.find(
		(member) => member.kind === "fund" && member.active,
	);
	const payerOptions = activeFund
		? [...activePeople, activeFund]
		: activePeople;

	const [mode, setMode] = useState<RecurringMode>(editing?.mode ?? "fixed");
	const [description, setDescription] = useState(editing?.description ?? "");
	const [amountText, setAmountText] = useState(
		editing?.amount ? formatAmount(editing.amount) : "",
	);
	const [category, setCategory] = useState<RecurringExpenseDto["category"]>(
		editing?.category ?? null,
	);
	const [categoryId, setCategoryId] = useState<string | null>(
		editing?.categoryId ?? null,
	);
	const [payerId, setPayerId] = useState<string>(
		editing?.payersTemplate[0]?.memberId ??
			(payerOptions.some((m) => m.id === myMemberId) ? myMemberId : null) ??
			payerOptions[0]?.id ??
			"",
	);
	const [frequency, setFrequency] = useState<RecurringFrequency>(
		editing?.frequency ?? "monthly",
	);
	const [dayOfWeek, setDayOfWeek] = useState<number>(editing?.dayOfWeek ?? 1);
	const [dayOfMonth, setDayOfMonth] = useState<number>(
		editing?.dayOfMonth ?? new Date().getDate(),
	);
	const [monthOfYear, setMonthOfYear] = useState<number>(
		editing?.monthOfYear ?? new Date().getMonth() + 1,
	);
	const [idempotencyKey] = useState(() => crypto.randomUUID());

	const parsedAmount = parseAmountInput(amountText);
	const splitState = useSplitState(
		activePeople,
		parsedAmount ?? 0,
		editing?.splitTemplate ?? null,
		groupId,
	);

	const createMutation = useCreateRecurringExpense(groupId);
	const updateMutation = useUpdateRecurringExpense(groupId);
	const mutation = editing ? updateMutation : createMutation;

	const changeMode = (next: RecurringMode) => {
		setMode(next);
		if (
			next === "variable" &&
			splitState.method !== "equal" &&
			splitState.method !== "shares" &&
			splitState.method !== "percent"
		) {
			splitState.changeMode("equal");
		}
	};

	const scheduleFields =
		frequency === "weekly"
			? { dayOfWeek, dayOfMonth: null, monthOfYear: null }
			: frequency === "yearly"
				? { dayOfWeek: null, dayOfMonth, monthOfYear }
				: { dayOfWeek: null, dayOfMonth, monthOfYear: null };

	const splitTemplate = splitState.baseSplit;
	const candidate = {
		mode,
		description: description.trim(),
		amount: mode === "fixed" ? parsedAmount : null,
		category,
		categoryId,
		payersTemplate:
			mode === "fixed"
				? [{ memberId: payerId, amount: parsedAmount }]
				: [{ memberId: payerId }],
		splitTemplate,
		frequency,
		...scheduleFields,
	};
	const validated = CreateRecurringExpenseRequest.safeParse(candidate);
	const errorMessage = mutation.isError
		? mutation.error.code === "RECURRING_MEMBER_INACTIVE"
			? vi.recurring.pausedMemberInvalid
			: mutation.error.status === 403
				? vi.common.forbidden
				: vi.common.saveError
		: null;

	const handleSubmit = () => {
		if (!validated.success || mutation.isPending) return;
		if (editing) {
			const updateBody = UpdateRecurringExpenseRequest.parse(validated.data);
			updateMutation.mutate(
				{ recurringId: editing.id, request: updateBody },
				{ onSuccess: onClose },
			);
			return;
		}
		createMutation.mutate(
			{ request: validated.data, key: idempotencyKey },
			{ onSuccess: onClose },
		);
	};

	return (
		<div className="flex max-h-[90dvh] flex-col">
			<div className="flex items-center justify-between gap-3 border-b border-sunken px-5 py-4">
				<h2 id={titleId} className="truncate text-base font-black">
					{editing ? vi.recurring.editTitle : vi.recurring.createTitle}
				</h2>
				<button
					type="button"
					aria-label={vi.common.cancel}
					onClick={onClose}
					className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-surface text-ink"
				>
					<Icon name="close" size={18} />
				</button>
			</div>

			<div className="flex-1 space-y-4 overflow-y-auto p-5">
				<div className="grid gap-1.5">
					<p className="text-xs font-bold text-muted">
						{vi.recurring.modeLabel}
					</p>
					<div className="grid gap-1.5">
						<OnlineButton
							type="button"
							allowOffline
							aria-pressed={mode === "fixed"}
							onClick={() => changeMode("fixed")}
							className={`min-h-11 rounded-[16px] px-3 text-left text-xs font-bold ${
								mode === "fixed" ? "bg-ink text-on-ink" : "bg-surface text-ink"
							}`}
						>
							{vi.recurring.modeFixedDesc}
						</OnlineButton>
						<OnlineButton
							type="button"
							allowOffline
							aria-pressed={mode === "variable"}
							onClick={() => changeMode("variable")}
							className={`min-h-11 rounded-[16px] px-3 text-left text-xs font-bold ${
								mode === "variable"
									? "bg-ink text-on-ink"
									: "bg-surface text-ink"
							}`}
						>
							{vi.recurring.modeVariableDesc}
						</OnlineButton>
					</div>
				</div>

				<label className="grid gap-1 text-xs font-bold text-muted">
					{vi.recurring.titleLabel}
					<input
						type="text"
						maxLength={200}
						value={description}
						onChange={(event) => setDescription(event.target.value)}
						placeholder={vi.expenseForm.descriptionPlaceholder}
						className="h-12 rounded-[18px] bg-surface px-4 text-sm font-bold text-ink"
					/>
				</label>

				{mode === "fixed" && (
					<label className="grid gap-1 text-xs font-bold text-muted">
						{vi.recurring.amountLabel}
						<div className="flex h-12 items-center gap-2 rounded-[18px] bg-surface px-4">
							<input
								inputMode="numeric"
								value={amountText}
								onChange={(event) => {
									const raw = event.target.value.replace(/[^0-9]/g, "");
									if (!raw) {
										setAmountText("");
										return;
									}
									const value = parseAmountInput(raw);
									if (value !== null) setAmountText(formatAmount(value));
								}}
								placeholder="0"
								className="min-w-0 flex-1 bg-transparent text-right tabular-nums text-lg font-black text-ink outline-none"
							/>
							<span className="text-sm font-bold text-muted">
								{vi.common.currency}
							</span>
						</div>
					</label>
				)}

				<CategoryPicker
					groupId={groupId}
					categories={categories}
					value={category}
					categoryId={categoryId}
					onChange={(next) => {
						setCategory(next);
						if (next !== null) setCategoryId(null);
					}}
					onChangeCustom={(nextId) => {
						setCategoryId(nextId);
						if (nextId !== null) setCategory(null);
					}}
				/>

				<div className="grid gap-2">
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
								onClick={() => setFrequency(option.value)}
								className={`min-h-11 rounded-pill px-3 text-xs font-extrabold ${
									frequency === option.value
										? "bg-ink text-on-ink"
										: "bg-surface text-ink"
								}`}
							>
								{option.label}
							</OnlineButton>
						))}
					</div>

					{frequency === "weekly" ? (
						<label className="grid gap-1 text-xs font-bold text-muted">
							{vi.recurring.dayOfWeekLabel}
							<select
								value={dayOfWeek}
								onChange={(event) => setDayOfWeek(Number(event.target.value))}
								className="h-11 rounded-[14px] bg-surface px-3 text-sm font-bold text-ink"
							>
								{[1, 2, 3, 4, 5, 6, 7].map((day) => (
									<option key={day} value={day}>
										{weekdayLabel(day)}
									</option>
								))}
							</select>
						</label>
					) : (
						<div className="flex gap-2">
							{frequency === "yearly" && (
								<label className="grid flex-1 gap-1 text-xs font-bold text-muted">
									{vi.recurring.monthOfYearLabel}
									<select
										value={monthOfYear}
										onChange={(event) =>
											setMonthOfYear(Number(event.target.value))
										}
										className="h-11 rounded-[14px] bg-surface px-3 text-sm font-bold text-ink"
									>
										{Array.from({ length: 12 }, (_, idx) => idx + 1).map(
											(month) => (
												<option key={month} value={month}>
													{month}
												</option>
											),
										)}
									</select>
								</label>
							)}
							<label className="grid flex-1 gap-1 text-xs font-bold text-muted">
								{vi.recurring.dayOfMonthLabel}
								<select
									value={dayOfMonth}
									onChange={(event) =>
										setDayOfMonth(Number(event.target.value))
									}
									className="h-11 rounded-[14px] bg-surface px-3 text-sm font-bold text-ink"
								>
									{Array.from({ length: 31 }, (_, idx) => idx + 1).map(
										(day) => (
											<option key={day} value={day}>
												{day}
											</option>
										),
									)}
								</select>
							</label>
						</div>
					)}
				</div>

				<div className="grid gap-1.5">
					<p className="text-xs font-bold text-muted">
						{vi.recurring.payerLabel}
					</p>
					<div className="flex flex-wrap gap-2">
						{payerOptions.map((member) => (
							<OnlineButton
								key={member.id}
								type="button"
								allowOffline
								aria-pressed={payerId === member.id}
								onClick={() => setPayerId(member.id)}
								className={`flex min-h-11 items-center gap-2 rounded-pill px-3 text-xs font-extrabold ${
									payerId === member.id
										? "bg-ink text-on-ink"
										: "bg-surface text-ink"
								}`}
							>
								<MemberShape {...member} size={22} />
								<span>{member.name}</span>
							</OnlineButton>
						))}
					</div>
				</div>

				<div className="grid gap-2">
					<p className="text-xs font-bold text-muted">
						{vi.recurring.splitLabel}
					</p>
					<div className="flex flex-wrap gap-1.5">
						{SPLIT_METHODS.filter(
							(option) => mode === "fixed" || option.value !== "exact",
						).map((option) => (
							<OnlineButton
								key={option.value}
								type="button"
								allowOffline
								aria-pressed={splitState.method === option.value}
								onClick={() => splitState.changeMode(option.value)}
								className={`min-h-11 rounded-pill px-3 text-xs font-extrabold ${
									splitState.method === option.value
										? "bg-ink text-on-ink"
										: "bg-surface text-ink"
								}`}
							>
								{option.label}
							</OnlineButton>
						))}
					</div>
					<div className="grid gap-1.5">
						{splitState.selected.map((member) => (
							<SplitMemberRow
								key={member.id}
								member={member}
								method={splitState.method}
								value={
									splitState.values[member.id] ??
									(splitState.method === "shares" ? member.defaultWeight : "")
								}
								onChange={(value) => splitState.setValue(member.id, value)}
								onRemove={() => splitState.toggle(member.id)}
							/>
						))}
						{activePeople
							.filter((member) => !splitState.ids.includes(member.id))
							.map((member) => (
								<OnlineButton
									key={member.id}
									type="button"
									allowOffline
									onClick={() => splitState.toggle(member.id)}
									className="min-h-11 rounded-[18px] border-2 border-dashed border-muted px-3 text-xs font-bold text-ink"
								>
									+ {member.name}
								</OnlineButton>
							))}
					</div>
				</div>

				{errorMessage && (
					<p role="alert" className="text-xs font-bold text-debt">
						{errorMessage}
					</p>
				)}
			</div>

			<div className="border-t border-sunken p-4">
				<Button
					type="button"
					variant="accent"
					size="lg"
					disabled={!validated.success || mutation.isPending}
					onClick={handleSubmit}
					className="w-full"
				>
					{vi.recurring.saveAction}
				</Button>
			</div>
		</div>
	);
}
