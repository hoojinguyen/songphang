import Link from "next/link";
import { formatMoney } from "../../lib/money";

const COLOR_CLASSES = {
	ink: "bg-ink",
	mint: "bg-mint",
	sky: "bg-sky",
	coral: "bg-coral",
	lilac: "bg-lilac",
} as const;

export function BarRow({
	label,
	amount,
	maxAmount,
	color = "ink",
	href,
}: {
	label: string;
	amount: number;
	maxAmount: number;
	color?: keyof typeof COLOR_CLASSES;
	href?: string;
}) {
	const width =
		maxAmount > 0 && amount > 0 ? Math.min(100, (amount / maxAmount) * 100) : 0;
	const content = (
		<>
			<div className="flex items-baseline justify-between gap-2 text-sm">
				<span className="min-w-0 break-words font-bold text-ink">{label}</span>
				<span className="shrink-0 font-extrabold text-ink">
					{formatMoney(amount)}
				</span>
			</div>
			{amount > 0 && (
				<div className="h-3 overflow-hidden rounded-pill bg-sunken">
					<div
						className={`h-full rounded-pill ${COLOR_CLASSES[color]}`}
						style={{ width: `${width}%` }}
					/>
				</div>
			)}
		</>
	);
	if (href) {
		return (
			<Link
				href={href}
				className="grid min-h-11 content-center gap-1.5 rounded-[18px] px-2 py-2"
			>
				{content}
			</Link>
		);
	}
	return (
		<div className="grid min-h-11 content-center gap-1.5 px-2 py-2">
			{content}
		</div>
	);
}
