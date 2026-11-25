"use client";
import { isThemeMode, useThemeMode } from "../../lib/theme";
import { vi } from "../../messages/vi";
import { SegmentedControl } from "../ui/SegmentedControl";

const THEME_OPTIONS = [
	{ value: "system", label: vi.appearance.system },
	{ value: "light", label: vi.appearance.light },
	{ value: "dark", label: vi.appearance.dark },
];

export function AppearanceCard() {
	const [mode, setMode] = useThemeMode();

	return (
		<section className="grid gap-4 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.appearance.title}</h2>
			<SegmentedControl
				label={vi.appearance.title}
				options={THEME_OPTIONS}
				value={mode}
				allowOffline
				onChange={(nextValue) => {
					if (isThemeMode(nextValue)) setMode(nextValue);
				}}
			/>
		</section>
	);
}
