import path from "node:path";
import { z } from "@hono/zod-openapi";

const REPO_ROOT = path.resolve(import.meta.dirname, "../../..");

const EMPTY_TO_UNDEFINED = (value: unknown) =>
	value === "" ? undefined : value;

const FAKE_RECEIPT_FIXTURES = [
	"default",
	"clean",
	"tax-service",
	"mismatch",
	"not-a-receipt",
] as const;

export type FakeReceiptFixture = (typeof FAKE_RECEIPT_FIXTURES)[number];

const CONFIG_SCHEMA = z
	.object({
		APP_ENV: z.enum(["development", "production"]),
		DATABASE_URL: z
			.url({ protocol: /^postgres(ql)?$/, hostname: /.+/ })
			.max(8192),
		API_PORT: z
			.string()
			.regex(/^\d+$/)
			.transform(Number)
			.pipe(z.int().min(1).max(65535)),
		WEB_ORIGIN: z.url({ protocol: /^https?$/, hostname: /.+/ }).max(2048),
		GOOGLE_CLIENT_ID: z.string().max(1024).optional(),
		GOOGLE_CLIENT_SECRET: z.string().max(4096).optional(),
		DEV_LOGIN: z.enum(["true", "false"]),
		STORAGE_DIR: z.string().min(1).max(1024).default("./.data/uploads"),
		AI_PROVIDER: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.enum(["anthropic", "fake"]).optional(),
		),
		ANTHROPIC_API_KEY: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().max(1024).optional(),
		),
		AI_MODEL: z.preprocess(EMPTY_TO_UNDEFINED, z.string().max(256).optional()),
		AI_RECEIPTS_PER_USER_PER_DAY: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.coerce.number().int().min(1).max(10000).default(20),
		),
		AI_SENTENCES_PER_USER_PER_DAY: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.coerce.number().int().min(1).max(10000).default(100),
		),
		AI_CALLS_PER_MONTH: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.coerce.number().int().min(1).max(1_000_000).default(1000),
		),
		AI_FAKE_RECEIPT_FIXTURE: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.enum(FAKE_RECEIPT_FIXTURES).optional(),
		),
		TELEGRAM_PROVIDER: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.enum(["telegram", "console"]).optional(),
		),
		TELEGRAM_BOT_TOKEN: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().min(1).max(1024).optional(),
		),
		TELEGRAM_WEBHOOK_SECRET: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().max(512).optional(),
		),
		TELEGRAM_BOT_USERNAME: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().min(1).max(128).optional(),
		),
	})
	.superRefine((env, context) => {
		if (Boolean(env.GOOGLE_CLIENT_ID) !== Boolean(env.GOOGLE_CLIENT_SECRET)) {
			for (const name of ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET"]) {
				context.addIssue({
					code: "custom",
					path: [name],
					message: "Google client ID and secret must be configured together",
				});
			}
		}
		if (env.AI_PROVIDER === "anthropic") {
			if (!env.ANTHROPIC_API_KEY) {
				context.addIssue({
					code: "custom",
					path: ["ANTHROPIC_API_KEY"],
					message: "ANTHROPIC_API_KEY is required when AI_PROVIDER=anthropic",
				});
			}
			if (!env.AI_MODEL) {
				context.addIssue({
					code: "custom",
					path: ["AI_MODEL"],
					message: "AI_MODEL is required when AI_PROVIDER=anthropic",
				});
			}
			if (env.AI_FAKE_RECEIPT_FIXTURE) {
				context.addIssue({
					code: "custom",
					path: ["AI_FAKE_RECEIPT_FIXTURE"],
					message:
						"AI_FAKE_RECEIPT_FIXTURE cannot be set when AI_PROVIDER=anthropic",
				});
			}
		}
		if (env.APP_ENV === "production") {
			if (env.AI_PROVIDER === "fake") {
				context.addIssue({
					code: "custom",
					path: ["AI_PROVIDER"],
					message: "AI_PROVIDER=fake is forbidden in production",
				});
			}
			if (env.AI_FAKE_RECEIPT_FIXTURE) {
				context.addIssue({
					code: "custom",
					path: ["AI_FAKE_RECEIPT_FIXTURE"],
					message: "AI_FAKE_RECEIPT_FIXTURE is forbidden in production",
				});
			}
			if (env.TELEGRAM_PROVIDER === "console") {
				context.addIssue({
					code: "custom",
					path: ["TELEGRAM_PROVIDER"],
					message: "TELEGRAM_PROVIDER=console is forbidden in production",
				});
			}
		}
		if (env.TELEGRAM_PROVIDER !== undefined) {
			if (
				!env.TELEGRAM_WEBHOOK_SECRET ||
				env.TELEGRAM_WEBHOOK_SECRET.length < 32
			) {
				context.addIssue({
					code: "custom",
					path: ["TELEGRAM_WEBHOOK_SECRET"],
					message:
						"TELEGRAM_WEBHOOK_SECRET must be at least 32 characters when TELEGRAM_PROVIDER is set",
				});
			}
			if (!env.TELEGRAM_BOT_USERNAME) {
				context.addIssue({
					code: "custom",
					path: ["TELEGRAM_BOT_USERNAME"],
					message:
						"TELEGRAM_BOT_USERNAME is required when TELEGRAM_PROVIDER is set",
				});
			}
			if (env.TELEGRAM_PROVIDER === "telegram" && !env.TELEGRAM_BOT_TOKEN) {
				context.addIssue({
					code: "custom",
					path: ["TELEGRAM_BOT_TOKEN"],
					message:
						"TELEGRAM_BOT_TOKEN is required when TELEGRAM_PROVIDER=telegram",
				});
			}
		}
	})
	.transform((env) => ({
		appEnv: env.APP_ENV,
		googleClientId: env.GOOGLE_CLIENT_ID || undefined,
		googleClientSecret: env.GOOGLE_CLIENT_SECRET || undefined,
		databaseUrl: env.DATABASE_URL,
		apiPort: env.API_PORT,
		webOrigin: env.WEB_ORIGIN,
		devLogin: env.DEV_LOGIN === "true" && env.APP_ENV !== "production",
		storageDir: path.resolve(REPO_ROOT, env.STORAGE_DIR),
		aiProvider: env.AI_PROVIDER,
		anthropicApiKey: env.ANTHROPIC_API_KEY,
		aiModel: env.AI_MODEL,
		aiReceiptsPerUserPerDay: env.AI_RECEIPTS_PER_USER_PER_DAY,
		aiSentencesPerUserPerDay: env.AI_SENTENCES_PER_USER_PER_DAY,
		aiCallsPerMonth: env.AI_CALLS_PER_MONTH,
		aiFakeReceiptFixture: env.AI_FAKE_RECEIPT_FIXTURE,
		telegramProvider: env.TELEGRAM_PROVIDER ?? null,
		telegramBotToken: env.TELEGRAM_BOT_TOKEN,
		telegramWebhookSecret: env.TELEGRAM_WEBHOOK_SECRET,
		telegramBotUsername: env.TELEGRAM_BOT_USERNAME?.replace(/^@+/, ""),
	}));

export type Config = z.infer<typeof CONFIG_SCHEMA>;

export function loadConfig(env: Record<string, string | undefined>): Config {
	const result = CONFIG_SCHEMA.safeParse(env);
	if (!result.success) {
		const invalidNames = [
			...new Set(result.error.issues.map((issue) => issue.path[0])),
		];
		throw new Error(
			`Invalid environment variables: ${invalidNames.join(", ")}`,
		);
	}
	return result.data;
}
