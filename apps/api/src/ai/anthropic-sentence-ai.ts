import { z } from "@hono/zod-openapi";
import { type AnthropicDeps, anthropicMessages } from "@songphang/ai";
import { SentenceAiAnswer } from "@songphang/contract";
import {
	buildSentenceUserPrompt,
	SENTENCE_SYSTEM_PROMPT,
	SENTENCE_TOOL_NAME,
} from "./prompts/sentence.js";
import type {
	SentenceAi,
	SentenceAiInput,
	SentenceAiOutput,
} from "./sentence-ai.js";

const SENTENCE_TIMEOUT_MS = 8_000;
const SENTENCE_INPUT_SCHEMA = z.toJSONSchema(SentenceAiAnswer, {
	unrepresentable: "any",
});

export function createAnthropicSentenceAi(deps: AnthropicDeps): SentenceAi {
	return {
		async read(input: SentenceAiInput): Promise<SentenceAiOutput> {
			const response = await anthropicMessages(
				deps,
				{
					max_tokens: 2048,
					system: SENTENCE_SYSTEM_PROMPT,
					tools: [
						{
							name: SENTENCE_TOOL_NAME,
							description: "Record structured expense drafts from a sentence.",
							input_schema: SENTENCE_INPUT_SCHEMA,
						},
					],
					tool_choice: { type: "tool", name: SENTENCE_TOOL_NAME },
					messages: [
						{
							role: "user",
							content: buildSentenceUserPrompt(input),
						},
					],
				},
				SENTENCE_TOOL_NAME,
				SENTENCE_TIMEOUT_MS,
			);
			return {
				answer: response.toolInput,
				model: response.model,
				inputTokens: response.inputTokens,
				outputTokens: response.outputTokens,
			};
		},
	};
}
