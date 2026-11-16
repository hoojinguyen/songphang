"use client";
import {
	createContext,
	type ReactNode,
	useContext,
	useEffect,
	useState,
} from "react";
import { vi } from "../../messages/vi";
import { Icon } from "./Icon";
import { OnlineButton } from "./OnlineButton";

type Notice = { text: string; action?: { label: string; run: () => void } };
const Context = createContext<((notice: Notice) => void) | null>(null);
export function SnackbarProvider({ children }: { children: ReactNode }) {
	const [notice, setNotice] = useState<Notice | null>(null);
	useEffect(() => {
		if (!notice) return;
		const timer = setTimeout(() => setNotice(null), 6000);
		return () => clearTimeout(timer);
	}, [notice]);
	return (
		<Context.Provider value={setNotice}>
			{children}
			{notice && (
				<div
					role="status"
					className="fixed bottom-5 left-1/2 z-50 flex w-[calc(100%-40px)] max-w-[390px] -translate-x-1/2 items-center gap-3 rounded-[22px] bg-ink p-4 text-surface"
				>
					<span className="flex-1">{notice.text}</span>
					{notice.action && (
						<OnlineButton
							type="button"
							className="min-h-11 font-bold"
							onClick={() => {
								const action = notice.action;
								setNotice(null);
								action?.run();
							}}
						>
							{notice.action.label}
						</OnlineButton>
					)}
					<button
						type="button"
						aria-label={vi.common.cancel}
						className="flex size-11 items-center justify-center"
						onClick={() => setNotice(null)}
					>
						<Icon name="close" size={20} />
					</button>
				</div>
			)}
		</Context.Provider>
	);
}
export function useSnackbar() {
	const value = useContext(Context);
	if (!value) throw new Error("Snackbar provider missing");
	return value;
}
