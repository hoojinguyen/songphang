import {
	type AnthropicDeps,
	AnthropicTransportError,
	anthropicMessages,
} from "@songphang/ai";
import { ReceiptReading } from "@songphang/contract";
import { z } from "zod";
import {
	RECEIPT_SYSTEM_PROMPT,
	RECEIPT_TOOL_NAME,
	RECEIPT_USER_PROMPT,
} from "./prompts/receipt.js";
import type {
	ReceiptReader,
	ReceiptReaderInput,
	ReceiptReaderOutput,
} from "./receipt-reader.js";

const RECEIPT_TIMEOUT_MS = 30_000;
const RECEIPT_INPUT_SCHEMA = z.toJSONSchema(ReceiptReading, {
	unrepresentable: "any",
});

export function createAnthropicReceiptReader(
	deps: AnthropicDeps,
): ReceiptReader {
	return {
		async readReceipt(input: ReceiptReaderInput): Promise<ReceiptReaderOutput> {
			const response = await anthropicMessages(
				deps,
				{
					max_tokens: 4096,
					system: RECEIPT_SYSTEM_PROMPT,
					tools: [
						{
							name: RECEIPT_TOOL_NAME,
							description: "Record structured Vietnamese receipt reading.",
							input_schema: RECEIPT_INPUT_SCHEMA,
						},
					],
					tool_choice: { type: "tool", name: RECEIPT_TOOL_NAME },
					messages: [
						{
							role: "user",
							content: [
								{
									type: "image",
									source: {
										type: "base64",
										media_type: input.mimeType,
										data: input.imageBytes.toString("base64"),
									},
								},
								{
									type: "text",
									text: RECEIPT_USER_PROMPT,
								},
							],
						},
					],
				},
				RECEIPT_TOOL_NAME,
				RECEIPT_TIMEOUT_MS,
			);

			const { toolInput, ...usage } = response;
			const reading = ReceiptReading.safeParse(toolInput);
			if (!reading.success) {
				throw new AnthropicTransportError({
					status: 200,
					retryable: false,
					errorType: "invalid_reading",
					usage,
				});
			}
			return { reading: reading.data, ...usage };
		},
	};
}
