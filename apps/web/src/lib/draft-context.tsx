"use client";
import type {
	CreateTransactionRequest,
	ParseDraft,
	ParsedDraftResult,
	ParseResponse,
} from "@songphang/contract";
import { createContext, type ReactNode, useContext, useState } from "react";

const INTERACTIVE_ISSUES = new Set([
	"MEMBER_AMBIGUOUS",
	"COUNT_MISMATCH",
	"DESCRIPTION_MISSING",
]);

export function isRuleInteractiveQuestion(
	item: Pick<ParsedDraftResult, "status" | "issues">,
	reader: ParseResponse["reader"],
) {
	return (
		reader !== "ai" &&
		item.status === "needs_input" &&
		item.issues.some((issue) => INTERACTIVE_ISSUES.has(issue.code))
	);
}

export type SentenceDraft = {
	sentence: string;
	itemIndex?: number | undefined;
	draft: ParseResponse["draft"];
	issues: ParseResponse["issues"];
	spans: ParseResponse["spans"];
};

export type QueuedDraft = ParsedDraftResult & {
	idempotencyKey: string;
	occurredAt: string;
	submittedRequest?: CreateTransactionRequest | undefined;
	categoryOverride?:
		| {
				category: ParseDraft["category"];
				categoryId: string | null;
		  }
		| undefined;
};

export type DraftQueue = {
	sentence: string;
	reader: ParseResponse["reader"];
	spans: ParseResponse["spans"];
	items: QueuedDraft[];
	index: number;
};

const Context = createContext<{
	sentence: string;
	setSentence: (s: string) => void;
	draft: SentenceDraft | null;
	setDraft: (d: SentenceDraft | null) => void;
	queue: DraftQueue | null;
	setQueue: (q: DraftQueue | null) => void;
	clear: () => void;
} | null>(null);
export function DraftProvider({ children }: { children: ReactNode }) {
	const [sentence, setSentence] = useState("");
	const [draft, setDraft] = useState<SentenceDraft | null>(null);
	const [queue, setQueue] = useState<DraftQueue | null>(null);
	return (
		<Context.Provider
			value={{
				sentence,
				setSentence,
				draft,
				setDraft,
				queue,
				setQueue,
				clear: () => {
					setSentence("");
					setDraft(null);
					setQueue(null);
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
