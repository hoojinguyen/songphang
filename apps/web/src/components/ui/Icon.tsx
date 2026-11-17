const PATHS = {
	"wifi-off":
		"M3 9c5-5 13-5 18 0M6.5 12.5c3-3 8-3 11 0M10 16c1.2-1 2.8-1 4 0M4 4l16 16",
	send: "M12 19V5M6 11l6-6 6 6",
	"arrow-right": "M4 12h16M14 6l6 6-6 6",
	check: "M5 12l5 5 9-10",
	warning: "M12 8v5M12 17h.01",
	plus: "M12 5v14M5 12h14",
	back: "M15 18l-6-6 6-6",
	close: "M6 6l12 12M18 6L6 18",
	image:
		"M4 5h16v14H4zM8.5 10.5a1 1 0 100-2 1 1 0 000 2zM20 15l-5-5-6 6-3-3-2 2",
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
