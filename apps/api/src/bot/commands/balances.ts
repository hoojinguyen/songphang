import { listGroupMembers } from "@songphang/db";
import type { AppDeps } from "../../app.js";
import { BOT_MESSAGES, formatBotBalancesText } from "../../bot-messages.js";
import { getBalances } from "../../services/balances.js";
import type { ChatSender } from "../chat-sender.js";
import { replySenderNotLinked, resolveActor } from "../resolve-actor.js";

export async function handleBalancesCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; platformUserId: string },
): Promise<void> {
	const actor = await resolveActor(deps, input);
	if (actor.kind === "chat_not_linked") {
		await sender.send(input.chatId, BOT_MESSAGES.chatNotLinked);
		return;
	}
	if (actor.kind === "sender_not_linked") {
		await replySenderNotLinked(deps, sender, input);
		return;
	}
	if (actor.kind === "not_in_group") {
		await sender.send(input.chatId, BOT_MESSAGES.notInGroup(actor.groupName));
		return;
	}

	const [balances, members] = await Promise.all([
		getBalances(deps, actor.groupId, actor.user.id),
		listGroupMembers(deps.db, actor.groupId),
	]);
	const memberNameById = new Map(members.map((m) => [m.id, m.name]));
	const text = formatBotBalancesText({
		groupName: actor.groupName,
		fundCash: balances.fund?.active ? balances.fund.cash : null,
		balances: balances.balances.map((entry) => ({
			name: memberNameById.get(entry.memberId) ?? "",
			balance: entry.balance,
		})),
		transfers: balances.transfers.map((transfer) => ({
			fromName: memberNameById.get(transfer.fromMemberId) ?? "",
			toName: memberNameById.get(transfer.toMemberId) ?? "",
			amount: transfer.amount,
		})),
	});
	const maxChunkLength = 4000;
	let current = "";
	for (const line of text.split("\n")) {
		const next = current ? `${current}\n${line}` : line;
		if (next.length > maxChunkLength && current) {
			await sender.send(input.chatId, current);
			current = line;
		} else {
			current = next;
		}
	}
	if (current) {
		await sender.send(input.chatId, current);
	}
}
