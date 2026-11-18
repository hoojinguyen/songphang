import { CATEGORY_KEYWORDS } from "./category-keywords.ts";
import { foldVietnamese } from "./quick-entry/normalize.ts";

export type CategorySuggestion = { category: string } | { categoryId: string };

export function suggestCategory(
	description: string,
	custom: ReadonlyArray<{ id: string; nameKey: string }> = [],
): CategorySuggestion | null {
	const cleaned = foldVietnamese(description.trim()).replace(/\s+/g, " ");
	if (cleaned.length === 0) {
		return null;
	}
	const words = cleaned.split(/[^a-z0-9]+/).filter((word) => word.length > 0);
	const padded = ` ${words.join(" ")} `;

	for (const item of custom) {
		const normalizedKey = foldVietnamese(item.nameKey.trim())
			.split(/[^a-z0-9]+/)
			.filter((word) => word.length > 0)
			.join(" ");
		if (
			normalizedKey.length > 0 &&
			(cleaned === normalizedKey || padded.includes(` ${normalizedKey} `))
		) {
			return { categoryId: item.id };
		}
	}

	let bestLength = 0;
	let bestCategory: string | null = null;
	for (const [keyword, category] of CATEGORY_KEYWORDS) {
		if (keyword.length > bestLength && padded.includes(` ${keyword} `)) {
			bestLength = keyword.length;
			bestCategory = category;
		}
	}

	return bestCategory === null ? null : { category: bestCategory };
}
