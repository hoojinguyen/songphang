import type { Config } from "../config.js";
import { createAnthropicSentenceAi } from "./anthropic-sentence-ai.js";
import { createFakeSentenceAi } from "./fake-sentence-ai.js";

export interface SentenceAiInput {
	sentence: string;
	members: Array<{ ref: string; name: string }>;
	writerRef: string | null;
}

export interface SentenceAiOutput {
	answer: unknown;
	model: string;
	inputTokens: number;
	outputTokens: number;
}

export interface SentenceAi {
	read(input: SentenceAiInput): Promise<SentenceAiOutput>;
}

export function selectSentenceAi(config: Config): SentenceAi | null {
	if (!config.aiProvider) {
		return null;
	}
	if (config.aiProvider === "fake") {
		return createFakeSentenceAi();
	}
	if (!config.anthropicApiKey || !config.aiModel) {
		throw new Error(
			"Anthropic sentence AI requires ANTHROPIC_API_KEY and AI_MODEL",
		);
	}
	return createAnthropicSentenceAi({
		apiKey: config.anthropicApiKey,
		model: config.aiModel,
	});
}
