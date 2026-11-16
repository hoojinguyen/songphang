"use client";
import type { ParseResponse } from "@songphang/contract";
import { createContext, type ReactNode, useContext, useState } from "react";
export type SentenceDraft = {
	sentence: string;
	draft: ParseResponse["draft"];
	issues: ParseResponse["issues"];
	spans: ParseResponse["spans"];
};
const Context = createContext<{
	sentence: string;
	setSentence: (s: string) => void;
	draft: SentenceDraft | null;
	setDraft: (d: SentenceDraft | null) => void;
	clear: () => void;
} | null>(null);
export function DraftProvider({ children }: { children: ReactNode }) {
	const [sentence, setSentence] = useState("");
	const [draft, setDraft] = useState<SentenceDraft | null>(null);
	return (
		<Context.Provider
			value={{
				sentence,
				setSentence,
				draft,
				setDraft,
				clear: () => {
					setSentence("");
					setDraft(null);
				},
			}}
		>
			{children}
		</Context.Provider>
	);
}
export function useDraft() {
	const value = useContext(Context);
	if (!value) throw new Error("Draft provider missing");
	return value;
}
