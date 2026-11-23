import { createPrivateKey } from "node:crypto";
import path from "node:path";
import { z } from "zod";

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

function validateEcP256PrivateKey(
	rawPem: string,
	fieldPath: string,
	context: z.RefinementCtx,
): void {
	try {
		const key = createPrivateKey(rawPem);
		if (key.asymmetricKeyType !== "ec") {
			context.addIssue({
				code: "custom",
				path: [fieldPath],
				message: `${fieldPath} must be an EC private key`,
			});
		} else {
			const curve = key.asymmetricKeyDetails?.namedCurve;
			if (curve !== "prime256v1" && curve !== "p256") {
				context.addIssue({
					code: "custom",
					path: [fieldPath],
					message: `${fieldPath} must use the P-256 (prime256v1) curve`,
				});
			}
		}
	} catch {
		context.addIssue({
			code: "custom",
			path: [fieldPath],
			message: `${fieldPath} is invalid or malformed PEM`,
		});
	}
}

const WORKER_CONFIG_SCHEMA = z
	.object({
		APP_ENV: z.enum(["development", "production"]),
		DATABASE_URL: z
			.url({ protocol: /^postgres(ql)?$/, hostname: /.+/ })
			.max(8192),
		WEB_ORIGIN: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z
				.url({ protocol: /^https?$/, hostname: /.+/ })
				.max(2048)
				.optional(),
		),
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
		PUSH_PROVIDER: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.enum(["apns", "console"]).optional(),
		),
		APPLE_BUNDLE_ID: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().min(1).max(255).optional(),
		),
		APPLE_TEAM_ID: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z
				.string()
				.regex(/^[A-Z0-9]{10}$/)
				.optional(),
		),
		APPLE_KEY_ID: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z
				.string()
				.regex(/^[A-Z0-9]{10}$/)
				.optional(),
		),
		APPLE_PRIVATE_KEY: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().min(1).max(8192).optional(),
		),
		APNS_KEY_ID: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z
				.string()
				.regex(/^[A-Z0-9]{10}$/)
				.optional(),
		),
		APNS_PRIVATE_KEY: z.preprocess(
			EMPTY_TO_UNDEFINED,
			z.string().min(1).max(8192).optional(),
		),
	})
	.superRefine((env, context) => {
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
			if (!env.WEB_ORIGIN) {
				context.addIssue({
					code: "custom",
					path: ["WEB_ORIGIN"],
					message: "WEB_ORIGIN is required in production",
				});
			}
			if (env.PUSH_PROVIDER === "console") {
				context.addIssue({
					code: "custom",
					path: ["PUSH_PROVIDER"],
					message: "PUSH_PROVIDER=console is forbidden in production",
				});
			}
		}
		if (env.PUSH_PROVIDER === "apns") {
			if (!env.APPLE_BUNDLE_ID) {
				context.addIssue({
					code: "custom",
					path: ["APPLE_BUNDLE_ID"],
					message: "APPLE_BUNDLE_ID is required when PUSH_PROVIDER=apns",
				});
			}
			if (!env.APPLE_TEAM_ID) {
				context.addIssue({
					code: "custom",
					path: ["APPLE_TEAM_ID"],
					message: "APPLE_TEAM_ID is required when PUSH_PROVIDER=apns",
				});
			}
			if (!(env.APNS_KEY_ID ?? env.APPLE_KEY_ID)) {
				context.addIssue({
					code: "custom",
					path: ["APNS_KEY_ID"],
					message:
						"APNS_KEY_ID or APPLE_KEY_ID is required when PUSH_PROVIDER=apns",
				});
			}
			const privateKeySource = env.APNS_PRIVATE_KEY
				? "APNS_PRIVATE_KEY"
				: "APPLE_PRIVATE_KEY";
			const privateKeyRaw = (
				env.APNS_PRIVATE_KEY ?? env.APPLE_PRIVATE_KEY
			)?.replace(/\\n/g, "\n");
			if (!privateKeyRaw) {
				context.addIssue({
					code: "custom",
					path: ["APNS_PRIVATE_KEY"],
					message:
						"APNS_PRIVATE_KEY or APPLE_PRIVATE_KEY is required when PUSH_PROVIDER=apns",
				});
			} else {
				validateEcP256PrivateKey(privateKeyRaw, privateKeySource, context);
			}
		}
	})
	.transform((env) => ({
		appEnv: env.APP_ENV,
		databaseUrl: env.DATABASE_URL,
		webOrigin: env.WEB_ORIGIN ?? "http://localhost:3000",
		storageDir: path.resolve(REPO_ROOT, env.STORAGE_DIR),
		aiProvider: env.AI_PROVIDER,
		anthropicApiKey: env.ANTHROPIC_API_KEY,
		aiModel: env.AI_MODEL,
		aiReceiptsPerUserPerDay: env.AI_RECEIPTS_PER_USER_PER_DAY,
		aiSentencesPerUserPerDay: env.AI_SENTENCES_PER_USER_PER_DAY,
		aiCallsPerMonth: env.AI_CALLS_PER_MONTH,
		aiFakeReceiptFixture: env.AI_FAKE_RECEIPT_FIXTURE,
		pushProvider: env.PUSH_PROVIDER,
		appleBundleId: env.APPLE_BUNDLE_ID,
		appleTeamId: env.APPLE_TEAM_ID,
		apnsKeyId: env.APNS_KEY_ID ?? env.APPLE_KEY_ID,
		apnsPrivateKey: (env.APNS_PRIVATE_KEY ?? env.APPLE_PRIVATE_KEY)?.replace(
			/\\n/g,
			"\n",
		),
	}));

export type WorkerConfig = z.infer<typeof WORKER_CONFIG_SCHEMA>;

export function loadWorkerConfig(
	env: Record<string, string | undefined>,
): WorkerConfig {
	const result = WORKER_CONFIG_SCHEMA.safeParse(env);
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
