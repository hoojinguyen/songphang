import { type ParseRequest, ParseResponse } from "@songphang/contract";
import { computeShares, readSentence } from "@songphang/core";
import { listGroupMembers } from "@songphang/db";
import type { AppDeps } from "../app.js";
export async function parseSentence(
	deps: AppDeps,
	input: { groupId: string; memberId: string | null; request: ParseRequest },
): Promise<ParseResponse> {
	const text = input.request.text.normalize("NFC");
	const members = await listGroupMembers(deps.db, input.groupId);
	const result = readSentence({
		text,
		members: members.map((member) => ({
			id: member.id,
			name: member.name,
			kind: member.kind === "fund" ? "fund" : "person",
			active: member.active,
			position: member.position,
		})),
		writerMemberId: input.memberId,
	});
	const { payerMemberId, ...draft } = result.draft;
	const shares =
		result.status === "ok" && draft.amount !== null && draft.split
			? computeShares(
					draft.amount,
					draft.split,
					members.map((m) => m.id),
				)
			: null;
	if (shares && !shares.ok) throw new Error("Reader returned an invalid split");
	return ParseResponse.parse({
		...result,
		text,
		draft: {
			...draft,
			type: "expense",
			payers:
				payerMemberId && draft.amount !== null
					? [{ memberId: payerMemberId, amount: draft.amount }]
					: [],
		},
		...(shares?.ok ? { shares: shares.shares } : {}),
	});
}
