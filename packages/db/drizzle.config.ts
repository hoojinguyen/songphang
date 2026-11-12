import { defineConfig } from "drizzle-kit";

export default defineConfig({
	dialect: "postgresql",
	schema: [
		"./src/schema.ts",
		"./src/schema-groups.ts",
		"./src/schema-transactions.ts",
		"./src/schema-records.ts",
	],
	out: "./drizzle",
});
