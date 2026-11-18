import type { MemberDto } from "@songphang/contract";
import type { ReactNode } from "react";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { ShareShapes } from "../quick-entry/ShareShapes";
import { ItemsAssignmentPanel } from "../receipt/ItemsAssignmentPanel";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";
import { SplitMemberRow } from "./SplitMemberRow";
import { SplitModeTabs } from "./SplitModeTabs";
import { SplitStatus } from "./SplitStatus";
import type { useSplitState } from "./use-split-state";
export function SplitEditor({
	banner,
	state,
	members,
	amount,
	description,
	payerLine,
	shares,
	allowItems = true,
	onDone,
}: {
	banner?: ReactNode;
	state: ReturnType<typeof useSplitState>;
	members: MemberDto[];
	amount: number;
	description: string;
	payerLine: string;
	shares: readonly { memberId: string; amount: number }[];
	allowItems?: boolean;
	onDone: () => void;
}) {
	const displayedAmount =
		state.method === "items" && state.itemsComputedAmount !== undefined
			? state.itemsComputedAmount
			: amount;
	return (
		<section
			aria-label={vi.split.changeLabel}
			className="fixed inset-y-0 left-1/2 z-20 flex w-full max-w-[430px] -translate-x-1/2 flex-col gap-4 overflow-y-auto bg-bg px-5 py-6"
		>
			{banner}
			<header className="flex items-center gap-3">
				<OnlineButton
					allowOffline
					type="button"
					onClick={onDone}
					aria-label={vi.common.back}
					className="flex size-11 shrink-0 items-center justify-center rounded-pill bg-surface"
				>
					<Icon name="back" size={22} />
				</OnlineButton>
				<div className="min-w-0 flex-1">
					<h1 className="break-words text-[17px] font-extrabold">
						{description}
					</h1>
					<p className="text-xs text-muted">{payerLine}</p>
				</div>
				<p className="text-[22px] font-black">{formatMoney(displayedAmount)}</p>
			</header>
			<SplitModeTabs
				value={state.method}
				onChange={state.changeMode}
				allowItems={allowItems}
			/>
			{state.method === "items" ? (
				<ItemsAssignmentPanel
					items={state.items}
					extras={state.extras}
					selectedItemId={state.selectedItemId}
					activePeople={members}
					previewData={state.itemsPreview.data}
					previewCurrent={state.itemsPreview.current}
					previewError={state.itemsPreview.isError}
					onSelectItem={state.setSelectedItemId}
					onChangeItem={state.onChangeItem}
					onRemoveItem={state.onRemoveItem}
					onAddItem={state.onAddItem}
					onToggleMemberOnSelected={state.onToggleMemberOnSelected}
					onSplitRemainingEqual={state.onSplitRemainingEqual}
					onAddExtra={state.onAddExtra}
					onChangeExtra={state.onChangeExtra}
					onRemoveExtra={state.onRemoveExtra}
				/>
			) : (
				<>
					{shares.length > 0 ? (
						<ShareShapes
							shares={state.selected.map((member) => ({
								member,
								amount:
									shares.find((s) => s.memberId === member.id)?.amount ?? 0,
							}))}
						/>
					) : (
						<div className="flex flex-wrap justify-center gap-3 rounded-[30px] bg-bg p-4">
							{state.selected.map((member) => (
								<div
									key={member.id}
									className="grid justify-items-center gap-2"
								>
									<MemberShape {...member} size={56} />
									<span>{member.name}</span>
									<span>{vi.common.pendingValue}</span>
								</div>
							))}
						</div>
					)}

					{state.selected.map((member) => (
						<SplitMemberRow
							key={member.id}
							member={member}
							method={state.method}
							value={
								state.values[member.id] ??
								(state.method === "shares" ? member.defaultWeight : "")
							}
							onChange={(value) => state.setValue(member.id, value)}
							onRemove={() => state.toggle(member.id)}
						/>
					))}
					{members
						.filter((member) => !state.ids.includes(member.id))
						.map((member) => (
							<OnlineButton
								key={member.id}
								type="button"
								className="min-h-14 rounded-[26px] border-2 border-dashed border-muted p-3 text-sm font-bold"
								onClick={() => state.toggle(member.id)}
							>
								{t(vi.split.addMember, { name: member.name })}
							</OnlineButton>
						))}
					{state.method === "exact" &&
						state.blankCount === 0 &&
						state.rest > 0 && (
							<Button
								variant="surface"
								className="min-h-14 rounded-[28px] bg-phrase-rest"
								onClick={() => state.setSpread(!state.spread)}
							>
								{state.spread
									? vi.split.undoSpread
									: t(vi.split.spreadRest, {
											amount: formatMoney(state.rest),
											count: String(state.selected.length),
										})}
							</Button>
						)}
				</>
			)}
			<div className="mt-auto grid gap-3">
				<SplitStatus {...state.status} />
				<Button variant="primary" size="lg" onClick={onDone} allowOffline>
					{vi.split.done}
				</Button>
			</div>
		</section>
	);
}
