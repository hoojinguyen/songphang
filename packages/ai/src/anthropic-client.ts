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

// Usage is read on its own so a billed response with an unusable body still reaches the cost ledger.
const USAGE_RESPONSE_SCHEMA = z.object({
	model: z.string().optional(),
	usage: z
		.object({
			input_tokens: z.number().int().nonnegative().default(0),
			output_tokens: z.number().int().nonnegative().default(0),
		})
		.optional(),
});

const MESSAGES_RESPONSE_SCHEMA = z.object({
	content: z.array(CONTENT_BLOCK_SCHEMA),
});

export interface AnthropicUsage {
	model: string;
	inputTokens: number;
	outputTokens: number;
}

export class AnthropicTransportError extends Error {
	readonly status: number;
	readonly retryable: boolean;
	readonly errorType: string | undefined;
	readonly usage: AnthropicUsage | null;

	constructor(input: {
		status: number;
		retryable: boolean;
		errorType?: string;
		usage?: AnthropicUsage;
	}) {
		super(
			input.errorType
				? `Anthropic API request failed (status=${input.status}, type=${input.errorType})`
				: `Anthropic API request failed (status=${input.status})`,
		);
		this.name = "AnthropicTransportError";
		this.status = input.status;
		this.retryable = input.retryable;
		this.errorType = input.errorType;
		this.usage = input.usage ?? null;
	}
}

function readUsage(json: unknown, fallbackModel: string): AnthropicUsage {
	const parsed = USAGE_RESPONSE_SCHEMA.safeParse(json);
	return {
		model: (parsed.success ? parsed.data.model : undefined) ?? fallbackModel,
		inputTokens: parsed.success ? (parsed.data.usage?.input_tokens ?? 0) : 0,
		outputTokens: parsed.success ? (parsed.data.usage?.output_tokens ?? 0) : 0,
	};
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
			const retryable = response.status >= 500;
			throw new AnthropicTransportError({
				status: response.status,
				retryable,
				...(errorType === undefined ? {} : { errorType }),
			});
		}

		let json: unknown;
		try {
			json = await response.json();
		} catch {
			throw new AnthropicTransportError({
				status: response.status,
				retryable: false,
				errorType: "invalid_shape",
			});
		}
		const usage = readUsage(json, deps.model);
		const parsed = MESSAGES_RESPONSE_SCHEMA.safeParse(json);
		if (!parsed.success) {
			throw new AnthropicTransportError({
				status: response.status,
				retryable: false,
				errorType: "invalid_shape",
				usage,
			});
		}

		const toolBlock = parsed.data.content.find(
			(block): block is z.infer<typeof TOOL_USE_BLOCK_SCHEMA> =>
				block.type === "tool_use" && "name" in block && block.name === toolName,
		);
		if (!toolBlock) {
			throw new AnthropicTransportError({
				status: response.status,
				retryable: false,
				errorType: "missing_tool_use",
				usage,
			});
		}

		return { ...usage, toolInput: toolBlock.input };
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
			throw new AnthropicTransportError({
				status: 0,
				retryable: true,
				errorType: "timeout",
			});
		}
		throw new AnthropicTransportError({
			status: 0,
			retryable: true,
			errorType: "network",
		});
	} finally {
		clearTimeout(timer);
	}
}
