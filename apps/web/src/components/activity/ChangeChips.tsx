import type { ChangeChip } from "../../lib/activity-sentences";
export function ChangeChips({ chips }: { chips: ChangeChip[] }) {
	return (
		<div className="flex flex-wrap gap-2 text-[13px] font-bold">
			{chips.map((chip) => (
				<span key={chip.field} className="flex flex-wrap items-center gap-1">
					{chips.length > 1 && <span>{chip.field}</span>}
					<del className="rounded-xl bg-bg px-[10px] py-[5px]">
						{chip.before}
					</del>
					<span aria-hidden="true">→</span>
					<span className="rounded-xl bg-phrase-amount px-[10px] py-[5px]">
						{chip.after}
					</span>
				</span>
			))}
		</div>
	);
}
