"use client";
import { useSyncExternalStore } from "react";
import {
	connectionServerSnapshot,
	connectionSnapshot,
	subscribeConnection,
} from "./network-state";
export function useConnection() {
	return useSyncExternalStore(
		subscribeConnection,
		connectionSnapshot,
		connectionServerSnapshot,
	);
}
export function useOnline() {
	return useConnection().online;
}
