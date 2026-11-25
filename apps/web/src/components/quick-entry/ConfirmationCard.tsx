"use client";
import type {
	CategoryDto,
	MemberDto,
	ParseDraft,
	ParseResponse,
} from "@songphang/contract";
import { type ReactNode, useId, useState } from "react";
import { formatAmount, formatCompactAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { CategoryPicker } from "../expense-form/CategoryPicker";
import { CATEGORY_COLORS } from "../settings/CategoryRow";
import { Button } from "../ui/Button";
import { ShareShapes } from "./ShareShapes";
export function ConfirmationCard({
	result,
	members,
	groupId,
	categories = [],
	onChangeCategory,
	onEdit,
	onSave,
	onSkip,
	disabled,
	children,
	saveLabel,
	skipLabel,
	indexLabel,
	overBudget,
}: {
	result: ParseResponse;
	members: MemberDto[];
	groupId?: string | undefined;
	categories?: CategoryDto[] | undefined;
	onChangeCategory?:
		| ((category: ParseDraft["category"], categoryId: string | null) => void)
		| undefined;
	onEdit: () => void;
	onSave: () => void;
	onSkip?: (() => void) | undefined;
	disabled: boolean;
	children?: ReactNode | undefined;
	saveLabel?: string | undefined;
	skipLabel?: string | undefined;
	indexLabel?: string | undefined;
	overBudget?: boolean | undefined;
}) {
	const [pickerOpen, setPickerOpen] = useState(false);
	const pickerId = useId();
	const { draft, shares = [] } = result;
	const customCategory = draft.categoryId
		? categories.find((c) => c.id === draft.categoryId)
		: undefined;
	const categoryLabel = draft.category
		? vi.expenseForm.categories[draft.category]
		: customCategory
			? customCategory.archived
				? `${customCategory.name} (${vi.categories.archivedTag})`
				: customCategory.name
			: null;
	const payer = members.find((m) => m.id === draft.payers[0]?.memberId);
	const split = draft.split;
	const name = (id: string) => members.find((m) => m.id === id)?.name ?? "";
	const equal = shares.every((s) => s.amount === shares[0]?.amount);
	const notIncluded = members.filter(
		(m) =>
			m.kind === "person" &&
			m.active &&
			!shares.some((s) => s.memberId === m.id),
	);
	const rest =
		split?.method === "exact" && draft.amount !== null
			? draft.amount - split.entries.reduce((n, e) => n + e.amount, 0)
			: 0;
	return (
		<section className="grid max-h-[85dvh] gap-3 overflow-y-auto rounded-[36px] bg-surface px-[18px] pb-[18px] pt-4">
			<div className="flex items-center justify-between gap-2">
				<p className="text-[13px] font-semibold text-muted">
					{vi.compose.understood}
				</p>
				{indexLabel && (
					<span className="rounded-[12px] bg-sunken px-2.5 py-0.5 text-xs font-extrabold text-ink">
						{indexLabel}
					</span>
				)}
			</div>
			{result.reader === "ai" && (
				<p
					role="note"
					className="rounded-[18px] bg-sunken px-3 py-2 text-xs font-bold text-ink"
				>
					{vi.compose.aiNote}
				</p>
			)}
			{draft.description && (
				<h2 className="text-base font-extrabold text-ink">
					{draft.description}
				</h2>
			)}
			{draft.amount !== null && (
				<p className="break-words tabular-nums text-[36px] sm:text-[44px] font-black leading-tight">
					<mark className="rounded-xl bg-phrase-amount px-1.5 py-0.5">
						{formatAmount(draft.amount)}
					</mark>{" "}
					<span className="text-[20px] text-muted">{vi.common.currency}</span>
				</p>
			)}
			<div className="flex flex-wrap gap-2 text-[13px] font-bold">
				{payer && (
					<span className="rounded-[14px] bg-phrase-payer px-3 py-[6px]">
						{result.reader === "ai" ||
						result.spans.some((s) => s.kind === "payer")
							? t(vi.compose.payer, { name: payer.name })
							: vi.compose.payerDefault}
					</span>
				)}
				{shares.length > 0 && split && (
					<span className="rounded-[14px] bg-phrase-split px-3 py-[6px]">
						{split.method === "exact"
							? t(vi.compose.exact, {
									parts: split.entries
										.map(
											(e) =>
												`${name(e.memberId)} ${formatCompactAmount(e.amount)}`,
										)
										.join(" · "),
								})
							: t(equal ? vi.compose.equal : vi.compose.equalUneven, {
									count: String(shares.length),
									amount: formatAmount(shares[0]?.amount ?? 0),
								})}
					</span>
				)}
				{rest > 0 && (
					<span className="rounded-[14px] bg-phrase-rest px-3 py-[6px]">
						{t(vi.compose.rest, {
							amount: formatAmount(rest),
							count: String(shares.length),
						})}
					</span>
				)}
			</div>
			{(categoryLabel !== null ||
				pickerOpen ||
				(onChangeCategory !== undefined && groupId !== undefined)) && (
				<div className="grid gap-2">
					<div className="flex flex-wrap items-center gap-2">
						{onChangeCategory && groupId ? (
							<button
								type="button"
								aria-expanded={pickerOpen}
								aria-controls={pickerId}
								onClick={() => setPickerOpen((open) => !open)}
								className="inline-flex min-h-11 items-center gap-2 rounded-[22px] bg-sunken px-4 text-[13px] font-bold text-ink"
							>
								{customCategory && (
									<span
										aria-hidden="true"
										className={`h-3 w-3 shrink-0 rounded-full ${CATEGORY_COLORS[customCategory.color].bg}`}
									/>
								)}
								<span>{categoryLabel ?? vi.expenseForm.categoryLabel}</span>
							</button>
						) : categoryLabel ? (
							<span className="inline-flex min-h-9 items-center gap-2 rounded-[18px] bg-sunken px-3 text-[13px] font-bold text-ink">
								{customCategory && (
									<span
										aria-hidden="true"
										className={`h-3 w-3 shrink-0 rounded-full ${CATEGORY_COLORS[customCategory.color].bg}`}
									/>
								)}
								<span>{categoryLabel}</span>
							</span>
						) : null}
					</div>
					{pickerOpen && groupId && onChangeCategory && (
						<div id={pickerId} className="min-w-0">
							<CategoryPicker
								groupId={groupId}
								categories={categories}
								value={draft.category}
								categoryId={draft.categoryId}
								onChange={(next) => onChangeCategory(next, null)}
								onChangeCustom={(nextId) => onChangeCategory(null, nextId)}
							/>
						</div>
					)}
				</div>
			)}
			{shares.length > 0 && (
				<ShareShapes
					shares={shares.flatMap((s) => {
						const member = members.find((m) => m.id === s.memberId);
						return member ? [{ member, amount: s.amount }] : [];
					})}
				/>
			)}
			{overBudget && (
				<p
					role="status"
					className="rounded-[18px] bg-coral px-3 py-2 text-xs font-bold text-on-accent"
				>
					{vi.budget.overWarning}
				</p>
			)}
			{children}
			<p className="text-xs text-muted">
				{shares.length > 0 && notIncluded.length > 0
					? t(vi.compose.notIncluded, {
							names: notIncluded.map((m) => m.name).join(", "),
						})
					: ""}{" "}
				{vi.compose.nothingSaved}
			</p>
			{skipLabel && onSkip ? (
				<div className="grid gap-2">
					<Button
						variant="accent"
						size="lg"
						onClick={onSave}
						disabled={disabled}
						style={{ height: 60 }}
						className="w-full text-[17px] font-black"
					>
						{saveLabel ?? vi.compose.save}
					</Button>
					<div className="flex gap-3">
						<Button
							variant="surface"
							size="lg"
							onClick={onEdit}
							style={{ height: 60 }}
							className="flex-1 bg-bg"
						>
							{vi.compose.edit}
						</Button>
						<Button
							variant="surface"
							size="lg"
							onClick={onSkip}
							disabled={disabled}
							style={{ height: 60 }}
							className="flex-1 bg-bg"
						>
							{skipLabel}
						</Button>
					</div>
				</div>
			) : (
				<div className="flex gap-3">
					<Button
						variant="surface"
						size="lg"
						onClick={onEdit}
						style={{ height: 60 }}
						className="flex-1 bg-bg"
					>
						{vi.compose.edit}
					</Button>
					<Button
						variant="accent"
						size="lg"
						onClick={onSave}
						disabled={disabled}
						style={{ height: 60 }}
						className="flex-[1.6] text-[17px] font-black"
					>
						{saveLabel ?? vi.compose.save}
					</Button>
				</div>
			)}
		</section>
	);
}
