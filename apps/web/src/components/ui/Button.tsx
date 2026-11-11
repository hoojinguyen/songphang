import type { ButtonHTMLAttributes } from "react";

type ButtonProps = {
	variant: "primary" | "accent" | "surface";
	size?: "md" | "lg";
} & ButtonHTMLAttributes<HTMLButtonElement>;

const VARIANTS = {
	primary: "bg-ink text-surface",
	accent: "bg-accent text-ink",
	surface: "bg-surface text-ink",
} as const;
const SIZES = { md: "h-control-md", lg: "h-control-lg" } as const;

export function Button({
	variant,
	size = "md",
	type = "button",
	className = "",
	...props
}: ButtonProps) {
	return (
		<button
			{...props}
			type={type}
			className={`inline-flex min-w-11 items-center justify-center rounded-pill px-6 font-bold focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink disabled:cursor-not-allowed disabled:bg-sunken disabled:text-muted ${VARIANTS[variant]} ${SIZES[size]} ${className}`}
		/>
	);
}
