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
	camera: "M4 7h3l2-2h6l2 2h3v12H4zM12 16a3 3 0 100-6 3 3 0 000 6z",
	trash: "M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3",
	comment:
		"M21 12c0 4.418-4.03 8-9 8a9.86 9.86 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z",
	bell: "M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0",
	search: "M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.35-4.35",
	home: "M3 12l9-9 9 9M5 10v9h4v-5h6v5h4v-9",
	grid: "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
	person: "M12 12a4 4 0 100-8 4 4 0 000 8zM4 20c0-4 3.6-7 8-7s8 3 8 7",
	"dots-horizontal": "M5 12h.01M12 12h.01M19 12h.01",
	moon: "M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z",
	sun: "M12 2v2M12 20v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M2 12h2M20 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42M12 6a6 6 0 100 12 6 6 0 000-12z",
	"circle-half": "M12 2a10 10 0 010 20V2z",
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
			strokeLinecap="round"
			strokeLinejoin="round"
			aria-hidden="true"
		>
			<path d={PATHS[name]} />
		</svg>
	);
}
