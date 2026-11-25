"use client";
import { useSyncExternalStore } from "react";

export type ThemeMode = "system" | "light" | "dark";

const THEME_STORAGE_KEY = "sp-theme";
const THEME_CHANGE_EVENT = "sp-theme-change";

export function isThemeMode(value: unknown): value is ThemeMode {
	return value === "system" || value === "light" || value === "dark";
}

export function readThemeMode(): ThemeMode {
	if (typeof window === "undefined") return "system";
	try {
		const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
		return isThemeMode(stored) ? stored : "system";
	} catch {
		return "system";
	}
}

export function applyThemeMode(mode: ThemeMode): void {
	if (typeof document === "undefined") return;
	document.documentElement.dataset.theme = mode;
}

export function writeThemeMode(mode: ThemeMode): void {
	if (typeof window !== "undefined") {
		try {
			window.localStorage.setItem(THEME_STORAGE_KEY, mode);
		} catch {
			// Storage may be unavailable in restricted browser contexts; DOM theme still updates.
		}
		applyThemeMode(mode);
		window.dispatchEvent(new Event(THEME_CHANGE_EVENT));
	}
}

function subscribeThemeMode(onStoreChange: () => void): () => void {
	if (typeof window === "undefined") return () => {};
	const onStorage = (event: StorageEvent) => {
		if (event.key === null || event.key === THEME_STORAGE_KEY) {
			applyThemeMode(readThemeMode());
			onStoreChange();
		}
	};
	window.addEventListener("storage", onStorage);
	window.addEventListener(THEME_CHANGE_EVENT, onStoreChange);
	return () => {
		window.removeEventListener("storage", onStorage);
		window.removeEventListener(THEME_CHANGE_EVENT, onStoreChange);
	};
}

function getServerThemeMode(): ThemeMode {
	return "system";
}

export function useThemeMode(): [ThemeMode, (mode: ThemeMode) => void] {
	const mode = useSyncExternalStore(
		subscribeThemeMode,
		readThemeMode,
		getServerThemeMode,
	);
	return [mode, writeThemeMode];
}
