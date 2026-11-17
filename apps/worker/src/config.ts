import { z } from "zod";

const WORKER_CONFIG_SCHEMA = z
	.object({
		APP_ENV: z.enum(["development", "production"]),
		DATABASE_URL: z
			.url({ protocol: /^postgres(ql)?$/, hostname: /.+/ })
			.max(8192),
	})
	.transform((env) => ({
		appEnv: env.APP_ENV,
		databaseUrl: env.DATABASE_URL,
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
