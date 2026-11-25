"use client";
import { usePathname } from "next/navigation";
import {
	createContext,
	type ReactNode,
	useCallback,
	useContext,
	useEffect,
	useState,
} from "react";

type SelectedPreview = {
	groupId: string;
	transactionId: string;
};

type DesktopInspectorContextValue = {
	selectedTx: SelectedPreview | null;
	selectTx: (groupId: string, transactionId: string) => void;
	clearTx: () => void;
};

const DesktopInspectorContext = createContext<DesktopInspectorContextValue>({
	selectedTx: null,
	selectTx: () => {},
	clearTx: () => {},
});

export function DesktopInspectorProvider({
	currentGroupId,
	children,
}: {
	currentGroupId: string | null;
	children: ReactNode;
}) {
	const pathname = usePathname();
	const [selectedTx, setSelectedTx] = useState<SelectedPreview | null>(null);
	const isGroupFeedRoute =
		currentGroupId !== null && /^\/g\/[^/]+\/?$/.test(pathname);

	useEffect(() => {
		setSelectedTx((current) =>
			isGroupFeedRoute && current && current.groupId === currentGroupId
				? current
				: null,
		);
	}, [currentGroupId, isGroupFeedRoute]);

	const selectTx = useCallback((groupId: string, transactionId: string) => {
		setSelectedTx({ groupId, transactionId });
	}, []);

	const clearTx = useCallback(() => {
		setSelectedTx(null);
	}, []);

	return (
		<DesktopInspectorContext.Provider value={{ selectedTx, selectTx, clearTx }}>
			{children}
		</DesktopInspectorContext.Provider>
	);
}

export function useDesktopInspector() {
	return useContext(DesktopInspectorContext);
}
