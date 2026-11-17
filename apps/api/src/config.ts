import path from "node:path";
import { z } from "@hono/zod-openapi";

const REPO_ROOT = path.resolve(import.meta.dirname, "../../..");

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
	})
	.superRefine((env, context) => {
		if (Boolean(env.GOOGLE_CLIENT_ID) === Boolean(env.GOOGLE_CLIENT_SECRET))
			return;
		for (const name of ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET"])
			context.addIssue({
				code: "custom",
				path: [name],
				message: "Google client ID and secret must be configured together",
			});
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
