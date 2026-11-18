import { GroupRole } from "@songphang/contract";
import {
	findChatIdentity,
	findChatLinkByChat,
	findGroupAccess,
	findUserById,
	insertChatLinkCode,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { BOT_MESSAGES } from "../bot-messages.js";
import type { ChatSender } from "./chat-sender.js";
import {
	generateLinkCode,
	hashLinkCode,
	LINK_CODE_TTL_MS,
} from "./link-codes.js";

export type ResolvedUser = NonNullable<
	Awaited<ReturnType<typeof findUserById>>
>;
export type ResolvedChatLink = NonNullable<
	Awaited<ReturnType<typeof findChatLinkByChat>>
>;

export type ActorResolution =
	| { kind: "chat_not_linked" }
	| { kind: "sender_not_linked"; chatLink: ResolvedChatLink }
	| {
			kind: "not_in_group";
			chatLink: ResolvedChatLink;
			groupName: string;
			user: ResolvedUser;
	  }
	| {
			kind: "ok";
			chatLink: ResolvedChatLink;
			user: ResolvedUser;
			groupId: string;
			groupName: string;
			role: GroupRole;
			memberId: string | null;
	  };

export async function resolveActor(
	deps: Pick<AppDeps, "db">,
	input: { chatId: string; platformUserId: string },
): Promise<ActorResolution> {
	const chatLink = await findChatLinkByChat(deps.db, {
		platform: "telegram",
		chatId: input.chatId,
	});
	if (chatLink === null) {
		return { kind: "chat_not_linked" };
	}
	const identity = await findChatIdentity(deps.db, {
		platform: "telegram",
		platformUserId: input.platformUserId,
	});
	if (identity === null) {
		return { kind: "sender_not_linked", chatLink };
	}
	const user = await findUserById(deps.db, identity.userId);
	if (user === null || !user.emailVerified) {
		return { kind: "sender_not_linked", chatLink };
	}
	const access = await findGroupAccess(deps.db, chatLink.groupId, user.id);
	if (access === null) {
		return {
			kind: "not_in_group",
			chatLink,
			groupName: chatLink.groupName,
			user,
		};
	}
	return {
		kind: "ok",
		chatLink,
		user,
		groupId: chatLink.groupId,
		groupName: chatLink.groupName,
		role: GroupRole.parse(access.role),
		memberId: access.memberId,
	};
}

export async function replySenderNotLinked(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; platformUserId: string },
): Promise<void> {
	const now = deps.now();
	const code = generateLinkCode();
	await insertChatLinkCode(deps.db, {
		codeHash: hashLinkCode(code),
		purpose: "user",
		groupId: null,
		platform: "telegram",
		platformUserId: input.platformUserId,
		createdBy: null,
		expiresAt: new Date(now.getTime() + LINK_CODE_TTL_MS),
		usedAt: null,
	});
	const url = `${deps.config.webOrigin}/link/telegram?code=${encodeURIComponent(code)}`;
	await sender.send(input.chatId, BOT_MESSAGES.senderNotLinked, [
		{ text: BOT_MESSAGES.linkAccountButton, url },
	]);
}
