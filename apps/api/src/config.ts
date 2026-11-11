import { z } from "@hono/zod-openapi";

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
		DEV_LOGIN: z.enum(["true", "false"]),
	})
	.transform((env) => ({
		appEnv: env.APP_ENV,
		databaseUrl: env.DATABASE_URL,
		apiPort: env.API_PORT,
		webOrigin: env.WEB_ORIGIN,
		devLogin: env.DEV_LOGIN === "true" && env.APP_ENV !== "production",
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
