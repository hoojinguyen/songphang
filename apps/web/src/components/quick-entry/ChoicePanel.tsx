import type { MemberDto } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { OnlineButton } from "../ui/OnlineButton";
export function ChoicePanel({
	members,
	selected,
	count,
	title,
	reason,
	onChoose,
}: {
	members: MemberDto[];
	selected: string[];
	count: number;
	title: string;
	reason: string;
	onChoose: (id: string) => void;
}) {
	return (
		<section className="grid gap-3 rounded-[30px] bg-bg p-4">
			<div className="flex items-center justify-between gap-2">
				<h3 className="text-xl font-extrabold">{title}</h3>
				<span className="text-[13px]">
					{t(vi.compose.chosen, {
						selected: String(selected.length),
						count: String(count),
					})}
				</span>
			</div>
			<div className="grid grid-cols-4 gap-2">
				{members.map((m) => (
					<OnlineButton
						key={m.id}
						type="button"
						aria-pressed={selected.includes(m.id)}
						disabled={
							count !== 1 &&
							selected.length >= count &&
							!selected.includes(m.id)
						}
						onClick={() => onChoose(m.id)}
						className={`grid min-h-20 justify-items-center gap-1 rounded-[20px] border-[3px] p-1 text-[13px] ${selected.includes(m.id) ? "border-ink" : "border-transparent"}`}
					>
						<MemberShape {...m} size={52} />
						{m.name}
					</OnlineButton>
				))}
			</div>
			<p className="text-xs text-muted">{reason}</p>
		</section>
	);
}
