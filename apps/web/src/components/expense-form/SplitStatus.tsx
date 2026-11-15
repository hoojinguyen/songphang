import { Icon } from "../ui/Icon";
export function SplitStatus({
	text,
	matched,
}: {
	text: string;
	matched: boolean;
}) {
	return (
		<div
			role="status"
			className={`flex items-center gap-2 rounded-[22px] p-4 text-sm font-bold ${matched ? "bg-phrase-split" : "bg-debt-soft"}`}
		>
			<Icon name={matched ? "check" : "warning"} size={20} />
			<span>{text}</span>
		</div>
	);
}
