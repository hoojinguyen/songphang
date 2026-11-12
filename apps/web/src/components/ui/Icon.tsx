const PATHS = {
	plus: "M12 5v14M5 12h14",
	back: "M15 18l-6-6 6-6",
	close: "M6 6l12 12M18 6L6 18",
};
export function Icon({
	name,
	size,
}: {
	name: keyof typeof PATHS;
	size: number;
}) {
	return (
		<svg
			width={size}
			height={size}
			viewBox="0 0 24 24"
			fill="none"
			stroke="currentColor"
			strokeWidth={2}
			aria-hidden="true"
		>
			<path d={PATHS[name]} />
		</svg>
	);
}
