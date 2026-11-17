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
		"./src/schema-settlements.ts",
		"./src/schema-categories.ts",
		"./src/schema-budgets.ts",
		"./src/schema-attachments.ts",
	],
	out: "./drizzle",
});
