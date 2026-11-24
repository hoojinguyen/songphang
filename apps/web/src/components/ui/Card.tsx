import type { ReactNode } from "react";

const TONES = {
	surface: "bg-surface text-ink",
	elevated: "bg-surface-elevated text-ink",
	accent: "bg-accent text-on-accent",
	sunken: "bg-sunken text-ink",
} as const;

export function Card({
	tone = "surface",
	className = "",
	children,
}: {
	tone?: "surface" | "elevated" | "accent" | "sunken";
	className?: string;
	children: ReactNode;
}) {
	return (
		<div className={`rounded-card p-6 ${TONES[tone]} ${className}`}>
			{children}
		</div>
	);
}
