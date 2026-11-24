"use client";
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
	const [selectedTx, setSelectedTx] = useState<SelectedPreview | null>(null);

	useEffect(() => {
		setSelectedTx((current) =>
			current && current.groupId === currentGroupId ? current : null,
		);
	}, [currentGroupId]);

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
