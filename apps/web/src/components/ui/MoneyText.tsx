import {
	formatAmount,
	formatCompactAmount,
	formatMoney,
	formatSignedAmount,
	formatSignedMoney,
	MONEY_TABULAR_CLASS,
} from "../../lib/money";

export type MoneyTextStyle =
	| "full"
	| "amountOnly"
	| "signed"
	| "signedFull"
	| "compact";

export type MoneyTextTone =
	| "default"
	| "credit"
	| "debt"
	| "muted"
	| "onAccent"
	| "onInk";

const TONE_CLASSES: Record<MoneyTextTone, string> = {
	default: "text-ink",
	credit: "text-credit",
	debt: "text-debt",
	muted: "text-muted",
	onAccent: "text-on-accent",
	onInk: "text-on-ink",
};

function formatMoneyByStyle(amount: number, style: MoneyTextStyle): string {
	switch (style) {
		case "full":
			return formatMoney(amount);
		case "amountOnly":
			return formatAmount(amount);
		case "signed":
			return formatSignedAmount(amount);
		case "signedFull":
			return formatSignedMoney(amount);
		case "compact":
			return formatCompactAmount(amount);
	}
}

export function MoneyText({
	amount,
	style = "full",
	tone = "default",
	className = "",
}: {
	amount: number;
	style?: MoneyTextStyle;
	tone?: MoneyTextTone;
	className?: string;
}) {
	return (
		<span
			className={`${MONEY_TABULAR_CLASS} ${TONE_CLASSES[tone]} ${className}`}
		>
			{formatMoneyByStyle(amount, style)}
		</span>
	);
}
