import { z } from "zod";

const ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

const ERROR_BODY_SCHEMA = z.object({
	error: z
		.object({
			type: z.string().optional(),
		})
		.optional(),
});

const TOOL_USE_BLOCK_SCHEMA = z.object({
	type: z.literal("tool_use"),
	name: z.string(),
	input: z.unknown(),
});

const CONTENT_BLOCK_SCHEMA = z.union([
	TOOL_USE_BLOCK_SCHEMA,
	z.object({ type: z.string() }).passthrough(),
]);

const MESSAGES_RESPONSE_SCHEMA = z.object({
	model: z.string().optional(),
	content: z.array(CONTENT_BLOCK_SCHEMA),
	usage: z
		.object({
			input_tokens: z.number().int().nonnegative().default(0),
			output_tokens: z.number().int().nonnegative().default(0),
		})
		.optional(),
});

export class AnthropicTransportError extends Error {
	readonly status: number;
	readonly retryable: boolean;
	readonly errorType: string | undefined;

	constructor(status: number, retryable: boolean, errorType?: string) {
		super(
			errorType
				? `Anthropic API request failed (status=${status}, type=${errorType})`
				: `Anthropic API request failed (status=${status})`,
		);
		this.name = "AnthropicTransportError";
		this.status = status;
		this.retryable = retryable;
		this.errorType = errorType;
	}
}

export interface AnthropicDeps {
	apiKey: string;
	model: string;
	fetchFn?: typeof fetch;
	baseUrl?: string;
}

export interface AnthropicMessagesResult {
	model: string;
	toolInput: unknown;
	inputTokens: number;
	outputTokens: number;
}

export async function anthropicMessages(
	deps: AnthropicDeps,
	body: Record<string, unknown>,
	toolName: string,
	timeoutMs: number,
): Promise<AnthropicMessagesResult> {
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(), timeoutMs);
	const fetchImpl = deps.fetchFn ?? fetch;
	const url = deps.baseUrl ?? ANTHROPIC_MESSAGES_URL;

	try {
		const response = await fetchImpl(url, {
			method: "POST",
			headers: {
				"content-type": "application/json",
				"x-api-key": deps.apiKey,
				"anthropic-version": ANTHROPIC_VERSION,
			},
			body: JSON.stringify({
				model: deps.model,
				...body,
			}),
			signal: controller.signal,
		});

		if (!response.ok) {
			let errorType: string | undefined;
			try {
				const rawError = await response.json();
				const parsed = ERROR_BODY_SCHEMA.safeParse(rawError);
				errorType = parsed.success ? parsed.data.error?.type : undefined;
			} catch {
				errorType = undefined;
			}
			const retryable = response.status === 429 || response.status >= 500;
			throw new AnthropicTransportError(response.status, retryable, errorType);
		}

		const json = await response.json();
		const parsed = MESSAGES_RESPONSE_SCHEMA.safeParse(json);
		if (!parsed.success) {
			throw new AnthropicTransportError(
				response.status,
				false,
				"invalid_shape",
			);
		}

		const toolBlock = parsed.data.content.find(
			(block): block is z.infer<typeof TOOL_USE_BLOCK_SCHEMA> =>
				block.type === "tool_use" && "name" in block && block.name === toolName,
		);
		if (!toolBlock) {
			throw new AnthropicTransportError(
				response.status,
				false,
				"missing_tool_use",
			);
		}

		return {
			model: parsed.data.model ?? deps.model,
			toolInput: toolBlock.input,
			inputTokens: parsed.data.usage?.input_tokens ?? 0,
			outputTokens: parsed.data.usage?.output_tokens ?? 0,
		};
	} catch (error) {
		if (error instanceof AnthropicTransportError) {
			throw error;
		}
		if (
			(error instanceof Error ||
				(typeof DOMException !== "undefined" &&
					error instanceof DOMException)) &&
			error.name === "AbortError"
		) {
			throw new AnthropicTransportError(0, true, "timeout");
		}
		throw new AnthropicTransportError(0, true, "network");
	} finally {
		clearTimeout(timer);
	}
}
