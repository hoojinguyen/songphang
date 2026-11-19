import { insertBotDraft, listGroupMembers } from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../../app.js";
import {
	BOT_MESSAGES,
	formatBotDraftText,
	formatParseIssue,
} from "../../bot-messages.js";
import { parseSentence } from "../../services/quick-entry.js";
import type { ChatSender } from "../chat-sender.js";
import { BotDraftPayload } from "../draft-payload.js";
import { LINK_CODE_TTL_MS } from "../link-codes.js";
import { replySenderNotLinked, resolveActor } from "../resolve-actor.js";

export async function handleExpenseCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; platformUserId: string; arg: string },
): Promise<void> {
	const actor = await resolveActor(deps, {
		chatId: input.chatId,
		platformUserId: input.platformUserId,
	});
	if (actor.kind === "chat_not_linked") {
		await sender.send(input.chatId, BOT_MESSAGES.chatNotLinked);
		return;
	}
	if (actor.kind === "sender_not_linked") {
		await replySenderNotLinked(deps, sender, {
			chatId: input.chatId,
			platformUserId: input.platformUserId,
		});
		return;
	}
	if (actor.kind === "not_in_group") {
		await sender.send(input.chatId, BOT_MESSAGES.notInGroup(actor.groupName));
		return;
	}
	if (actor.role === "viewer") {
		await sender.send(input.chatId, BOT_MESSAGES.viewerCannotAdd);
		return;
	}
	const sentence = input.arg.trim();
	if (sentence.length === 0) {
		await sender.send(input.chatId, BOT_MESSAGES.chiEmpty);
		return;
	}

	const openFormUrl = `${deps.config.webOrigin}/g/${actor.groupId}/tx/new?form&text=${encodeURIComponent(sentence.slice(0, 300))}`;
	if (sentence.length > 300) {
		await sender.send(
			input.chatId,
			BOT_MESSAGES.notUnderstood(`chưa hiểu "${sentence.slice(0, 40)}"`),
			[{ text: BOT_MESSAGES.openFormButton, url: openFormUrl }],
		);
		return;
	}

	const parsed = await parseSentence(deps, {
		groupId: actor.groupId,
		userId: actor.user.id,
		memberId: actor.memberId,
		request: { text: sentence, ai: true },
	});

	if (
		parsed.status !== "ok" ||
		!parsed.draft.description ||
		parsed.draft.amount === null ||
		parsed.draft.payers.length === 0 ||
		!parsed.draft.split ||
		!parsed.shares
	) {
		const issue = parsed.issues[0];
		const snippet = issue
			? parsed.text.slice(issue.start, issue.end).trim() || parsed.text
			: parsed.text;
		const issueText = issue
			? formatParseIssue({ code: issue.code, snippet })
			: `chưa hiểu "${snippet}"`;
		await sender.send(input.chatId, BOT_MESSAGES.notUnderstood(issueText), [
			{ text: BOT_MESSAGES.openFormButton, url: openFormUrl },
		]);
		return;
	}

	const now = deps.now();
	const payload = BotDraftPayload.parse({
		description: parsed.draft.description,
		amount: parsed.draft.amount,
		occurredAt: now.toISOString(),
		category: parsed.draft.category,
		categoryId: parsed.draft.categoryId,
		payers: parsed.draft.payers,
		split: parsed.draft.split,
	});
	const draftId = uuidv7();
	await insertBotDraft(deps.db, {
		id: draftId,
		chatLinkId: actor.chatLink.id,
		userId: actor.user.id,
		draft: payload,
		expiresAt: new Date(now.getTime() + LINK_CODE_TTL_MS),
		savedTransactionId: null,
		savedAt: null,
		createdAt: now,
	});

	const members = await listGroupMembers(deps.db, actor.groupId);
	const memberNameById = new Map(members.map((m) => [m.id, m.name]));
	const messageText = formatBotDraftText({
		reader: parsed.reader,
		description: payload.description,
		amount: payload.amount,
		payerNames: payload.payers.map((p) => memberNameById.get(p.memberId) ?? ""),
		shares: parsed.shares
			.filter((s) => s.amount > 0)
			.map((s) => ({
				name: memberNameById.get(s.memberId) ?? "",
				amount: s.amount,
			})),
	});
	await sender.send(input.chatId, messageText, [
		{ text: BOT_MESSAGES.saveButton, data: `s:${draftId}` },
		{ text: BOT_MESSAGES.dropButton, data: `d:${draftId}` },
	]);
}
