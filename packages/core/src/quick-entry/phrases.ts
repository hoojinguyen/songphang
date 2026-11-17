import type { SplitInput } from "../split.ts";
import {
	consume,
	fundShareIssue,
	nameIssue,
	type ReaderContext,
	readName,
} from "./names.ts";
export function readPayers(context: ReaderContext): {
	payerMemberId: string | null;
	explicit: boolean;
} {
	let explicit = false;
	const defaultChoice = context.memberChoices[0];
	let payerMemberId =
		context.writerMemberId ??
		(context.people.some((m) => m.id === defaultChoice)
			? (defaultChoice ?? null)
			: null);
	for (let index = 0; index < context.tokens.length; index++) {
		if (context.used.has(index) || context.tokens[index]?.kind !== "word")
			continue;
		const firstToken = context.tokens[index];
		const secondToken = context.tokens[index + 1];
		if (
			firstToken?.value === "tu" &&
			secondToken?.value === "quy" &&
			!context.used.has(index + 1)
		) {
			if (explicit) {
				context.issues.push({
					code: "TEXT_NOT_UNDERSTOOD",
					start: firstToken.start,
					end: secondToken.end,
					candidates: [],
				});
			} else {
				if (context.fund) payerMemberId = context.fund.id;
				else {
					payerMemberId = null;
					context.issues.push({
						code: "MEMBER_UNKNOWN",
						start: secondToken.start,
						end: secondToken.end,
						candidates: [],
					});
				}
				explicit = true;
			}
			consume(context, index, index + 2, "payer");
			index++;
			continue;
		}
		const name = readName(context, index);
		const after = index + name.length;
		if (context.tokens[after]?.value !== "tra") continue;
		if (explicit) {
			const first = context.tokens[index];
			const last = context.tokens[after];
			if (first && last)
				context.issues.push({
					code: "TEXT_NOT_UNDERSTOOD",
					start: first.start,
					end: last.end,
					candidates: [],
				});
		} else {
			nameIssue(context, index, name);
			payerMemberId = name.memberId;
			explicit = true;
		}
		consume(context, index, after + 1, "payer");
		index = after;
	}
	if (!explicit && !payerMemberId)
		context.issues.push({
			code: "MEMBER_AMBIGUOUS",
			start: 0,
			end: 0,
			candidates: context.people.map((member) => member.id),
		});
	return { payerMemberId, explicit };
}
export function readRemainder(
	context: ReaderContext,
	totalIndex: number,
): boolean {
	let found = false;
	for (let index = totalIndex + 1; index < context.tokens.length; index++) {
		if (
			["con", "lai", "chia", "deu"].every(
				(word, offset) =>
					context.tokens[index + offset]?.value === word &&
					!context.used.has(index + offset),
			)
		) {
			consume(context, index, index + 4, "remainder");
			if (found) {
				const token = context.tokens[index];
				if (token)
					context.issues.push({
						code: "TEXT_NOT_UNDERSTOOD",
						start: token.start,
						end: token.end,
						candidates: [],
					});
			}
			found = true;
		}
	}
	return found;
}
export function readEqual(
	context: ReaderContext,
	totalIndex: number,
): { split: SplitInput | null; explicit: boolean } {
	const all = context.people.map((member) => member.id);
	let explicit = false;
	let split: SplitInput | null = { method: "equal", members: all };
	for (let index = totalIndex + 1; index < context.tokens.length; index++) {
		if (context.used.has(index) || context.tokens[index]?.value !== "chia")
			continue;
		const start = context.tokens[index];
		if (!start) continue;
		if (explicit)
			context.issues.push({
				code: "TEXT_NOT_UNDERSTOOD",
				start: start.start,
				end: start.end,
				candidates: [],
			});
		explicit = true;
		const next = context.tokens[index + 1];
		if (next?.value === "deu") {
			consume(context, index, index + 2, "equal");
			continue;
		}
		if (next && /^\d+$/.test(next.value)) {
			const count = Number(next.value);
			consume(context, index, index + 2, "equal");
			if (!Number.isSafeInteger(count)) {
				split = null;
				context.issues.push({
					code: "TEXT_NOT_UNDERSTOOD",
					start: start.start,
					end: next.end,
					candidates: [],
				});
				continue;
			}
			if (count !== all.length) {
				split = null;
				context.issues.push({
					code: "COUNT_MISMATCH",
					start: start.start,
					end: next.end,
					candidates: all,
					count,
				});
			}
			continue;
		}
		const selected: string[] = [];
		let cursor = index + 1;
		let end = index + 1;
		while (cursor < context.tokens.length) {
			const token = context.tokens[cursor];
			if (!token || context.used.has(cursor) || token.kind === "number") break;
			if (token.value === "va" || /^[,.;:]$/.test(token.value)) {
				context.used.add(cursor);
				cursor++;
				continue;
			}
			if (token.kind !== "word") break;
			const name = readName(context, cursor);
			if (name.memberId && name.memberId === context.fund?.id)
				fundShareIssue(context, cursor, name.length);
			else {
				nameIssue(context, cursor, name);
				if (name.memberId && !selected.includes(name.memberId))
					selected.push(name.memberId);
			}
			for (let offset = 0; offset < name.length; offset++)
				context.used.add(cursor + offset);
			cursor += name.length;
			end = cursor;
		}
		consume(context, index, end, "equal");
		split =
			selected.length > 0
				? {
						method: "equal",
						members: context.people
							.filter((member) => selected.includes(member.id))
							.map((member) => member.id),
					}
				: null;
		if (end === index + 1)
			context.issues.push({
				code: "TEXT_NOT_UNDERSTOOD",
				start: start.start,
				end: start.end,
				candidates: [],
			});
	}
	return { split, explicit };
}
