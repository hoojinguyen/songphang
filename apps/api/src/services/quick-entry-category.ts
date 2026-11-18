import { ParseDraft, TransactionCategory } from "@songphang/contract";
import { suggestCategory } from "@songphang/core";

export type CustomCategory = { id: string; nameKey: string };

export function applySuggestedCategory(
	draft: ParseDraft,
	customCategories: readonly CustomCategory[],
): ParseDraft {
	if (
		draft.category !== null ||
		draft.categoryId !== null ||
		!draft.description
	) {
		return draft;
	}
	const suggestion = suggestCategory(draft.description, customCategories);
	if (!suggestion) {
		return draft;
	}
	if ("categoryId" in suggestion) {
		return ParseDraft.parse({
			...draft,
			category: null,
			categoryId: suggestion.categoryId,
		});
	}
	const builtIn = TransactionCategory.safeParse(suggestion.category);
	if (!builtIn.success) {
		return draft;
	}
	return ParseDraft.parse({
		...draft,
		category: builtIn.data,
		categoryId: null,
	});
}
