import { type AppDeps, createApp, OPENAPI_DOCUMENT_CONFIG } from "../app.js";
import { loadConfig } from "../config.js";
import { createEventHub } from "../events/hub.js";
import { createRateLimiter } from "../rate-limit.js";

const SNAPSHOT_ENV: Record<string, string> = {
	APP_ENV: "development",
	DATABASE_URL: "postgres://offline:offline@127.0.0.1:5432/offline",
	API_PORT: "4000",
	WEB_ORIGIN: "http://127.0.0.1:3000",
	DEV_LOGIN: "false",
	STORAGE_DIR: "./.data/uploads",
	GOOGLE_CLIENT_ID: "openapi-snapshot-client",
	GOOGLE_CLIENT_SECRET: "openapi-snapshot-secret",
	AI_PROVIDER: "fake",
	TELEGRAM_PROVIDER: "console",
	TELEGRAM_WEBHOOK_SECRET: "openapi_snapshot_placeholder_secret_32",
	TELEGRAM_BOT_USERNAME: "SongPhangBot",
	MIN_APP_VERSION_IOS: "0.0.0",
	MIN_APP_VERSION_ANDROID: "0.0.0",
	APPLE_PROVIDER: "fake",
	APPLE_BUNDLE_ID: "vn.songphang.app",
	APPLE_FAKE_JWKS_FILE: "./fixtures/apple-fake-jwks.json",
	PUSH_PROVIDER: "console",
};

function inertRuntimeDependency<T extends object>(label: string): T {
	// Route registration never touches I/O; this guard guarantees snapshot generation
	// stays completely offline and fails loudly if a future route tries runtime I/O.
	return new Proxy({} as T, {
		get(_target, property) {
			throw new Error(
				`Offline OpenAPI generation cannot access ${label}.${String(property)}`,
			);
		},
	});
}

export function normalizeOpenApiValue(value: unknown): unknown {
	if (Array.isArray(value)) {
		return value.map(normalizeOpenApiValue);
	}
	if (value !== null && typeof value === "object") {
		const record = value as Record<string, unknown>;
		const sorted: Record<string, unknown> = {};
		for (const key of Object.keys(record).sort()) {
			const entry = record[key];
			if (entry !== undefined) {
				sorted[key] = normalizeOpenApiValue(entry);
			}
		}
		return sorted;
	}
	return value;
}

export function buildOpenApiSnapshot(): Record<string, unknown> {
	const config = loadConfig(SNAPSHOT_ENV);
	const fixedNow = () => new Date(0);
	const deps: AppDeps = {
		config,
		db: inertRuntimeDependency<AppDeps["db"]>("db"),
		now: fixedNow,
		mailer: inertRuntimeDependency<AppDeps["mailer"]>("mailer"),
		rateLimiter: createRateLimiter(fixedNow),
		events: createEventHub(),
		enqueue: async () => {
			throw new Error("Offline OpenAPI generation cannot enqueue jobs");
		},
		fileStore: inertRuntimeDependency<AppDeps["fileStore"]>("fileStore"),
		sentenceAi: null,
		chatSender: null,
	};
	const app = createApp(deps);
	const raw = app.getOpenAPI31Document(OPENAPI_DOCUMENT_CONFIG);
	return normalizeOpenApiValue(raw) as Record<string, unknown>;
}

export function serializeOpenApiSnapshot(
	document: Record<string, unknown>,
): string {
	return `${JSON.stringify(document, null, "\t")}\n`;
}
