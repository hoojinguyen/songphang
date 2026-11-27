import type { MemberDto, PreviewExtrasResponse } from "@songphang/contract";
import { type ReactNode, useEffect, useRef, useState } from "react";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { ItemsAssignmentPanel } from "../receipt/ItemsAssignmentPanel";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";
import { ManualExtrasCard } from "./ManualExtrasCard";
import { SplitMemberRow } from "./SplitMemberRow";
import { SplitModeTabs } from "./SplitModeTabs";
import { SplitStatus } from "./SplitStatus";
import type { useSplitState } from "./use-split-state";

function useHoldToGrow(onPump: (id: string) => void) {
	const onPumpRef = useRef(onPump);
	useEffect(() => {
		onPumpRef.current = onPump;
	});

	const timerRef = useRef<NodeJS.Timeout | null>(null);
	const intervalRef = useRef<NodeJS.Timeout | null>(null);
	const [heldId, setHeldId] = useState<string | null>(null);
	const didPumpLongRef = useRef(false);

	const stop = () => {
		if (timerRef.current) clearTimeout(timerRef.current);
		if (intervalRef.current) clearInterval(intervalRef.current);
		timerRef.current = null;
		intervalRef.current = null;
		setHeldId(null);
	};

	useEffect(() => {
		return () => {
			if (timerRef.current) clearTimeout(timerRef.current);
			if (intervalRef.current) clearInterval(intervalRef.current);
		};
	}, []);

	const start = (id: string) => {
		stop();
		setHeldId(id);
		didPumpLongRef.current = false;
		timerRef.current = setTimeout(() => {
			didPumpLongRef.current = true;
			onPumpRef.current(id);
			intervalRef.current = setInterval(() => {
				onPumpRef.current(id);
			}, 180);
		}, 250);
	};

	const finish = (id: string) => {
		if (!didPumpLongRef.current && heldId === id) {
			onPumpRef.current(id);
		}
		stop();
	};

	return { heldId, start, finish, stop };
}
export function SplitEditor({
	banner,
	state,
	members,
	amount,
	computedAmount,
	extrasPreviewData,
	extrasPreviewCurrent = false,
	extrasPreviewError = false,
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
	computedAmount?: number | undefined;
	extrasPreviewData?: PreviewExtrasResponse | undefined;
	extrasPreviewCurrent?: boolean;
	extrasPreviewError?: boolean;
	description: string;
	payerLine: string;
	shares: readonly { memberId: string; amount: number }[];
	allowItems?: boolean;
	onDone: () => void;
}) {
	const displayedAmount =
		computedAmount !== undefined
			? computedAmount
			: state.method === "items" && state.itemsComputedAmount !== undefined
				? state.itemsComputedAmount
				: amount;
	const { heldId, start, finish, stop } = useHoldToGrow(state.pumpMember);
	const canPump =
		state.method === "shares" ||
		state.method === "percent" ||
		state.method === "exact";
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
					{state.extras.length > 0 && state.method !== "items" && (
						<p className="tabular-nums text-xs font-bold text-ink">
							{vi.extras.goodsSubtotal}: {formatMoney(amount)}
						</p>
					)}
				</div>
				<p className="tabular-nums text-[22px] font-black">
					{formatMoney(displayedAmount)}
				</p>
			</header>
			<SplitModeTabs
				value={state.method}
				onChange={state.changeMode}
				allowItems={allowItems}
			/>
			{state.method === "items" ? (
				<ItemsAssignmentPanel
					items={state.items}
					extras={state.receiptExtras}
					extrasAllocation={state.extrasAllocation}
					onChangeExtrasAllocation={state.setExtrasAllocation}
					selectedItemId={state.selectedItemId}
					activePeople={members}
					previewData={
						state.extras.length > 0
							? extrasPreviewData
							: state.itemsPreview.data
					}
					previewCurrent={
						state.extras.length > 0
							? extrasPreviewCurrent
							: state.itemsPreview.current
					}
					previewError={
						state.extras.length > 0
							? extrasPreviewError
							: state.itemsPreview.isError
					}
					onSelectItem={state.setSelectedItemId}
					onChangeItem={state.onChangeItem}
					onRemoveItem={state.onRemoveItem}
					onAddItem={state.onAddItem}
					onToggleMemberOnSelected={state.onToggleMemberOnSelected}
					onSplitRemainingEqual={state.onSplitRemainingEqual}
					onAddExtra={state.onAddExtra}
					onChangeExtra={state.onChangeExtra}
					onRemoveExtra={state.onRemoveExtra}
					extrasSection={
						<ManualExtrasCard
							extras={state.extras}
							extrasAllocation={state.extrasAllocation}
							resolvedExtras={extrasPreviewData?.resolvedExtras}
							computedAmount={extrasPreviewData?.computedAmount}
							previewCurrent={extrasPreviewCurrent}
							onChangeAllocation={state.setExtrasAllocation}
							onTogglePreset={state.onTogglePresetExtra}
							onAddExtra={state.onAddManualExtra}
							onChangeExtra={state.onChangeManualExtra}
							onRemoveExtra={state.onRemoveExtra}
						/>
					}
				/>
			) : (
				<>
					{canPump && (
						<p className="text-center text-xs font-semibold text-muted">
							{vi.split.holdToGrowHint}
						</p>
					)}
					<div className="flex max-h-[220px] flex-wrap justify-center gap-3 overflow-y-auto rounded-[30px] bg-bg p-4">
						{state.selected.map((member) => {
							const shareAmt = shares.find(
								(s) => s.memberId === member.id,
							)?.amount;
							const isHeld = heldId === member.id;

							return (
								<button
									key={member.id}
									type="button"
									disabled={!canPump}
									onPointerDown={() => canPump && start(member.id)}
									onPointerUp={() => canPump && finish(member.id)}
									onPointerLeave={stop}
									onPointerCancel={stop}
									onKeyDown={(e) => {
										if (!canPump) return;
										if (e.key === "Enter" || e.key === " ") {
											e.preventDefault();
											state.pumpMember(member.id);
										}
									}}
									aria-label={`${member.name}: ${vi.split.holdToGrowHint}`}
									title={vi.split.holdToGrowHint}
									className={`grid justify-items-center gap-1.5 rounded-[20px] p-2 transition-transform duration-300 motion-reduce:transition-none select-none focus:outline-none focus-visible:ring-2 focus-visible:ring-ink ${isHeld ? "scale-115" : "scale-100"}`}
								>
									<MemberShape {...member} size={52} />
									<span className="max-w-[70px] truncate text-[12px] font-bold text-ink">
										{member.name}
									</span>
									<span className="tabular-nums text-[11px] font-extrabold text-ink">
										{shareAmt !== undefined
											? formatMoney(shareAmt)
											: vi.common.pendingValue}
									</span>
								</button>
							);
						})}
					</div>

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
