import { vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
import type { SplitMethod } from "./use-split-state";
export const SPLIT_NAMES: Record<SplitMethod, string> = {
	equal: vi.split.methodEqual,
	exact: vi.split.methodExact,
	shares: vi.split.methodShares,
	percent: vi.split.methodPercent,
	items: vi.split.methodItems,
};
export function SplitModeTabs({
	value,
	onChange,
	allowItems = true,
}: {
	value: SplitMethod;
	onChange: (value: SplitMethod) => void;
	allowItems?: boolean;
}) {
	const tabs = [
		["equal", vi.split.modeEqual],
		["exact", vi.split.modeExact],
		["shares", vi.split.modeShares],
		["percent", vi.split.modePercent],
		...(allowItems ? ([["items", vi.split.modeItems]] as const) : []),
	] as const;
	return (
		<fieldset
			aria-label={vi.split.changeLabel}
			className="flex flex-wrap gap-2"
		>
			{tabs.map(([method, label]) => (
				<OnlineButton
					key={method}
					type="button"
					aria-pressed={value === method}
					onClick={() => onChange(method)}
					className={`h-[52px] rounded-[26px] px-3 font-extrabold ${value === method ? "flex-1 rounded-[20px] bg-ink text-[15px] text-surface" : "min-w-14 bg-surface text-[13px]"}`}
				>
					{label}
				</OnlineButton>
			))}
		</fieldset>
	);
}
