import type { SplitInput } from "../split.ts";
import { readAmount } from "./amounts.ts";
import {
	consume,
	fundShareIssue,
	nameIssue,
	type ReaderContext,
	readName,
} from "./names.ts";
export function readParts(
	context: ReaderContext,
	input: {
		totalIndex: number;
		amount: number;
		remainder: boolean;
		hasEqual: boolean;
	},
): SplitInput | null {
	const entries: { memberId: string; amount: number }[] = [];
	let total = 0;
	let found = false;
	for (
		let index = input.totalIndex + 1;
		index < context.tokens.length;
		index++
	) {
		if (context.used.has(index) || context.tokens[index]?.kind !== "word")
			continue;
		const name = readName(context, index);
		const number = context.tokens[index + name.length];
		if (number?.kind !== "number" || context.used.has(index + name.length))
			continue;
		const amount = readAmount(number.value, true);
		if (amount === null) continue;
		found = true;
		total += amount;
		if (name.memberId && name.memberId === context.fund?.id) {
			fundShareIssue(context, index, name.length);
		} else {
			nameIssue(context, index, name);
			if (name.memberId) {
				if (entries.some((entry) => entry.memberId === name.memberId)) {
					const token = context.tokens[index];
					if (token)
						context.issues.push({
							code: "TEXT_NOT_UNDERSTOOD",
							start: token.start,
							end: number.end,
							candidates: [],
						});
				} else entries.push({ memberId: name.memberId, amount });
			}
		}
		consume(context, index, index + name.length + 1, "exact");
		index += name.length;
	}
	if (!found) {
		if (input.remainder)
			context.issues.push({
				code: "TEXT_NOT_UNDERSTOOD",
				start: 0,
				end: context.text.length,
				candidates: [],
			});
		return null;
	}
	if (input.hasEqual)
		context.issues.push({
			code: "TEXT_NOT_UNDERSTOOD",
			start: 0,
			end: context.text.length,
			candidates: [],
		});
	if (total > input.amount || (!input.remainder && total !== input.amount))
		context.issues.push({
			code: "SUM_MISMATCH",
			start: 0,
			end: context.text.length,
			candidates: [],
			expected: input.amount,
			actual: total,
		});
	if (entries.length === 0) return null;
	const ordered = context.members.flatMap((member) => {
		const entry = entries.find((entry) => entry.memberId === member.id);
		return entry ? [entry] : [];
	});
	return {
		method: "exact",
		members: ordered.map((entry) => entry.memberId),
		entries: ordered,
		remainder: input.remainder ? "equal_among_all" : "none",
	};
}
