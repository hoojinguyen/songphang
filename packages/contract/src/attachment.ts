import { z } from "@hono/zod-openapi";

export const AttachmentContentType = z.enum([
	"image/jpeg",
	"image/png",
	"image/webp",
]);
export type AttachmentContentType = z.infer<typeof AttachmentContentType>;

export const AttachmentDto = z
	.object({
		id: z.uuid(),
		contentType: AttachmentContentType,
		byteSize: z.int().min(1).max(5_242_880),
		transactionId: z.uuid().nullable(),
		createdAt: z.iso.datetime(),
	})
	.openapi("AttachmentDto");
export type AttachmentDto = z.infer<typeof AttachmentDto>;

export const AttachmentUploadPurpose = z
	.enum(["expense", "transfer_proof"])
	.openapi("AttachmentUploadPurpose");
export type AttachmentUploadPurpose = z.infer<typeof AttachmentUploadPurpose>;

export const UploadAttachmentQuery = z.object({
	purpose: AttachmentUploadPurpose.optional(),
});
export type UploadAttachmentQuery = z.infer<typeof UploadAttachmentQuery>;

export const AttachmentResponse = z
	.object({ attachment: AttachmentDto })
	.openapi("AttachmentResponse");
export type AttachmentResponse = z.infer<typeof AttachmentResponse>;
