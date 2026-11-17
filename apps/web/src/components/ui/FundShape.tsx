export function FundShape({ name, size }: { name: string; size: number }) {
	return (
		<span
			role="img"
			aria-label={name}
			className="inline-flex shrink-0 items-center justify-center rounded-pill bg-sun"
			style={{ width: Math.round(size * 1.6), height: size }}
		/>
	);
}
