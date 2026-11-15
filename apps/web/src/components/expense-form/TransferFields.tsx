import type { MemberDto } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { MemberToggleGrid } from "./MemberToggleGrid";
export function TransferFields({
	members,
	from,
	to,
	onFrom,
	onTo,
}: {
	members: MemberDto[];
	from: string | null;
	to: string | null;
	onFrom: (id: string) => void;
	onTo: (id: string) => void;
}) {
	return (
		<>
			{[
				{
					label: vi.expenseForm.transferFrom,
					selected: from,
					onChange: onFrom,
					disabled: [],
				},
				{
					label: vi.expenseForm.transferTo,
					selected: to,
					onChange: onTo,
					disabled: from ? [from] : [],
				},
			].map((section) => (
				<section key={section.label} className="rounded-[30px] bg-surface p-3">
					<h2 className="mb-2 text-sm font-extrabold">{section.label}</h2>
					<MemberToggleGrid
						members={members}
						selectedIds={section.selected ? [section.selected] : []}
						onToggle={section.onChange}
						disabledIds={section.disabled}
						captionFor={(member) => member.name}
						label={section.label}
					/>
				</section>
			))}
		</>
	);
}
