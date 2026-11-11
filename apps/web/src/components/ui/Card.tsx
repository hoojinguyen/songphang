import type { ReactNode } from "react";

const TONES = {
	surface: "bg-surface",
	accent: "bg-accent",
	sunken: "bg-sunken",
} as const;

export function Card({
	tone = "surface",
	className = "",
	children,
}: {
	tone?: "surface" | "accent" | "sunken";
	className?: string;
	children: ReactNode;
}) {
	return (
		<div className={`rounded-card p-6 ${TONES[tone]} ${className}`}>
			{children}
		</div>
	);
}
