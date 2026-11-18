import type { ReceiptReading } from "@songphang/contract";
import type { WorkerConfig } from "../config.js";
import { createAnthropicReceiptReader } from "./anthropic-receipt-reader.js";
import { createFakeReceiptReader } from "./fake-receipt-reader.js";

export interface ReceiptReaderInput {
	imageBytes: Buffer;
	mimeType: "image/jpeg" | "image/png" | "image/webp";
	sha256: string;
}

export interface ReceiptReaderOutput {
	reading: ReceiptReading;
	model: string;
	inputTokens: number;
	outputTokens: number;
}

export interface ReceiptReader {
	readReceipt(input: ReceiptReaderInput): Promise<ReceiptReaderOutput>;
}

export function selectReceiptReader(
	config: WorkerConfig,
): ReceiptReader | null {
	if (!config.aiProvider) {
		return null;
	}
	if (config.aiProvider === "fake") {
		return createFakeReceiptReader(config.aiFakeReceiptFixture);
	}
	if (!config.anthropicApiKey || !config.aiModel) {
		throw new Error(
			"Anthropic receipt reader requires ANTHROPIC_API_KEY and AI_MODEL",
		);
	}
	return createAnthropicReceiptReader({
		apiKey: config.anthropicApiKey,
		model: config.aiModel,
	});
}
