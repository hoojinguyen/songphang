import { defineConfig } from "drizzle-kit";

export default defineConfig({
	dialect: "postgresql",
	schemaFilter: ["public"],
	schema: [
		"./src/schema.ts",
		"./src/schema-groups.ts",
		"./src/schema-transactions.ts",
		"./src/schema-records.ts",
		"./src/schema-accounts.ts",
		"./src/schema-payments.ts",
		"./src/schema-cycles.ts",
		"./src/schema-settlements.ts",
		"./src/schema-categories.ts",
		"./src/schema-budgets.ts",
		"./src/schema-attachments.ts",
		"./src/schema-scans.ts",
		"./src/schema-ai.ts",
		"./src/schema-comments.ts",
		"./src/schema-disputes.ts",
		"./src/schema-notifications.ts",
		"./src/schema-reminders.ts",
		"./src/schema-chat.ts",
		"./src/schema-push.ts",
	],
	out: "./drizzle",
});
