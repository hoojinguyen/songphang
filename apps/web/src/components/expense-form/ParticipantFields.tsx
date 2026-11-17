import { useCategories } from "../../lib/categories";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
import { CategoryPicker } from "./CategoryPicker";
import { MemberToggleGrid } from "./MemberToggleGrid";
import { PayerAmounts } from "./PayerAmounts";
import { SPLIT_NAMES } from "./SplitModeTabs";
import type { useExpenseForm } from "./use-expense-form";
export function ParticipantFields({
	form,
	myMemberId,
	onEdit,
}: {
	form: ReturnType<typeof useExpenseForm>;
	myMemberId: string | null;
	onEdit: () => void;
}) {
	const {
		groupId,
		type,
		category,
		setCategory,
		categoryId,
		setCategoryId,
		active,
		payerIds,
		togglePayer,
		payerAmounts,
		amount,
		setPayerAmount,
		splitState,
		sharers,
		setSharers,
		preview,
	} = form;
	const categories = useCategories(groupId);
	return (
		<>
			<CategoryPicker
				groupId={groupId}
				categories={categories.data ?? []}
				value={category}
				categoryId={categoryId}
				onChange={setCategory}
				onChangeCustom={setCategoryId}
			/>
			<section className="rounded-[30px] bg-surface p-3">
				<h2 className="mb-2 text-sm font-extrabold">
					{type === "income"
						? vi.expenseForm.receiverTitle
						: vi.expenseForm.payerTitle}
				</h2>
				<MemberToggleGrid
					members={active}
					selectedIds={payerIds}
					onToggle={togglePayer}
					captionFor={(member) =>
						member.id === myMemberId ? vi.common.you : member.name
					}
					label={
						type === "income"
							? vi.expenseForm.receiverTitle
							: vi.expenseForm.payerTitle
					}
				/>
			</section>
			{payerIds.length > 1 && (
				<PayerAmounts
					members={active.filter((member) => payerIds.includes(member.id))}
					values={payerAmounts}
					amount={amount}
					onChange={setPayerAmount}
				/>
			)}
			<section className="rounded-[30px] bg-surface p-3">
				<div className="mb-2 flex items-center justify-between">
					<h2 className="text-sm font-extrabold">
						{vi.expenseForm.sharersTitle}
					</h2>
					<OnlineButton
						type="button"
						onClick={() => onEdit()}
						className="min-h-11 rounded-[22px] bg-phrase-split px-3 text-xs font-extrabold"
					>
						{t(vi.split.change, { method: SPLIT_NAMES[splitState.method] })}
					</OnlineButton>
				</div>
				<MemberToggleGrid
					members={active}
					selectedIds={sharers}
					onToggle={(id) =>
						setSharers(
							sharers.includes(id)
								? sharers.filter((memberId) => memberId !== id)
								: [...sharers, id],
						)
					}
					captionFor={(member) => {
						if (!sharers.includes(member.id)) return member.name;
						const share = preview.current
							? preview.data?.shares.find(
									(share) => share.memberId === member.id,
								)
							: undefined;
						return share ? formatAmount(share.amount) : vi.common.pendingValue;
					}}
					label={vi.expenseForm.sharersTitle}
				/>
				{sharers.length === 0 && (
					<p role="alert" className="mt-2 text-xs text-muted">
						{vi.expenseForm.needSharer}
					</p>
				)}
			</section>
		</>
	);
}
