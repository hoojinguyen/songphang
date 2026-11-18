import { z } from "@hono/zod-openapi";

export const ChatPlatform = z.enum(["telegram"]).openapi("ChatPlatform");
export type ChatPlatform = z.infer<typeof ChatPlatform>;

export const CreateChatLinkCodeResponse = z
	.object({
		command: z.string(),
		botUsername: z.string().nullable(),
		expiresAt: z.iso.datetime(),
	})
	.openapi("CreateChatLinkCodeResponse");
export type CreateChatLinkCodeResponse = z.infer<
	typeof CreateChatLinkCodeResponse
>;

export const ChatLinkDto = z
	.object({
		id: z.uuid(),
		platform: ChatPlatform,
		chatId: z.string(),
		linkedAt: z.iso.datetime(),
	})
	.openapi("ChatLinkDto");
export type ChatLinkDto = z.infer<typeof ChatLinkDto>;

export const ChatLinksResponse = z
	.object({
		botUsername: z.string().nullable(),
		chatLinks: z.array(ChatLinkDto),
	})
	.openapi("ChatLinksResponse");
export type ChatLinksResponse = z.infer<typeof ChatLinksResponse>;

export const ChatIdentityDto = z
	.object({
		platform: ChatPlatform,
		linkedAt: z.iso.datetime(),
	})
	.openapi("ChatIdentityDto");
export type ChatIdentityDto = z.infer<typeof ChatIdentityDto>;

export const ChatIdentitiesResponse = z
	.object({
		chatIdentities: z.array(ChatIdentityDto),
	})
	.openapi("ChatIdentitiesResponse");
export type ChatIdentitiesResponse = z.infer<typeof ChatIdentitiesResponse>;

export const ClaimChatIdentityRequest = z
	.object({
		code: z.string().trim().min(1).max(32),
	})
	.openapi("ClaimChatIdentityRequest");
export type ClaimChatIdentityRequest = z.infer<typeof ClaimChatIdentityRequest>;

export const TelegramPairingStatus = z
	.enum([
		"pending_telegram",
		"telegram_confirmed",
		"completed",
		"cancelled",
		"expired",
	])
	.openapi("TelegramPairingStatus");
export type TelegramPairingStatus = z.infer<typeof TelegramPairingStatus>;

export const TelegramPairingDto = z
	.object({
		id: z.uuid(),
		status: TelegramPairingStatus,
		botUsername: z.string().nullable(),
		stagedPlatformUserId: z.string().nullable(),
		stagedPlatformName: z.string().nullable(),
		expiresAt: z.iso.datetime(),
	})
	.openapi("TelegramPairingDto");
export type TelegramPairingDto = z.infer<typeof TelegramPairingDto>;

export const StartTelegramPairingResponse = z
	.object({
		pairing: TelegramPairingDto,
		startCommand: z.string(),
		deepLinkUrl: z.string().nullable(),
	})
	.openapi("StartTelegramPairingResponse");
export type StartTelegramPairingResponse = z.infer<
	typeof StartTelegramPairingResponse
>;

export const TelegramPairingResponse = z
	.object({
		pairing: TelegramPairingDto,
	})
	.openapi("TelegramPairingResponse");
export type TelegramPairingResponse = z.infer<typeof TelegramPairingResponse>;
