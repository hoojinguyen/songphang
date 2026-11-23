import fs from "node:fs";
import path from "node:path";
import { buildOpenApiSnapshot, serializeOpenApiSnapshot } from "./build.js";
import { diffOpenApiSnapshots } from "./diff.js";

const DEFAULT_SNAPSHOT_PATH = path.resolve(
	import.meta.dirname,
	"../../../../packages/contract/openapi.json",
);

function readJsonRecord(filePath: string): Record<string, unknown> {
	const raw = fs.readFileSync(filePath, "utf8");
	const parsed: unknown = JSON.parse(raw);
	if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
		throw new Error(`Expected JSON object in ${filePath}`);
	}
	return parsed as Record<string, unknown>;
}

function parseArgs(argv: string[]): {
	command: "write" | "check" | "diff";
	snapshotPath: string;
	force: boolean;
	compareBase?: string;
	compareCandidate?: string;
} {
	const [command, ...rest] = argv;
	if (command === "diff") {
		const [base, candidate] = rest;
		if (!base || !candidate) {
			throw new Error("Usage: cli.ts diff <baseline.json> <candidate.json>");
		}
		return {
			command: "diff",
			snapshotPath: DEFAULT_SNAPSHOT_PATH,
			force: false,
			compareBase: path.resolve(base),
			compareCandidate: path.resolve(candidate),
		};
	}
	if (command !== "write" && command !== "check") {
		throw new Error(
			"Usage: cli.ts <write|check|diff> [--snapshot <path>] [--force]",
		);
	}
	let snapshotPath = DEFAULT_SNAPSHOT_PATH;
	let force = false;
	for (let index = 0; index < rest.length; index++) {
		if (rest[index] === "--snapshot") {
			const next = rest[index + 1];
			if (!next) throw new Error("--snapshot requires a path");
			snapshotPath = path.resolve(next);
			index++;
		} else if (rest[index] === "--force") {
			force = true;
		}
	}
	return { command, snapshotPath, force };
}

function printDiffReport(
	baseDoc: Record<string, unknown>,
	candidateDoc: Record<string, unknown>,
): { breakingCount: number; additiveCount: number; identical: boolean } {
	const result = diffOpenApiSnapshots(baseDoc, candidateDoc);
	for (const change of result.changes) {
		console.error(
			`  [${change.severity.toUpperCase()}] ${change.path}: ${change.reason}`,
		);
	}
	console.error(
		`Contract diff summary: ${result.breakingCount} breaking, ${result.additiveCount} additive`,
	);
	return result;
}

function main(): void {
	const parsed = parseArgs(process.argv.slice(2));

	if (parsed.command === "diff") {
		const baseDoc = readJsonRecord(parsed.compareBase ?? "");
		const candidateDoc = readJsonRecord(parsed.compareCandidate ?? "");
		const summary = printDiffReport(baseDoc, candidateDoc);
		if (summary.breakingCount > 0) process.exit(2);
		if (!summary.identical) process.exit(1);
		console.log("OpenAPI snapshots are identical.");
		return;
	}

	const generated = buildOpenApiSnapshot();
	const serialized = serializeOpenApiSnapshot(generated);

	if (parsed.command === "write") {
		if (fs.existsSync(parsed.snapshotPath)) {
			try {
				const committedDoc = readJsonRecord(parsed.snapshotPath);
				const diff = diffOpenApiSnapshots(committedDoc, generated);
				if (diff.breakingCount > 0 && !parsed.force) {
					console.error(
						`Refusing to overwrite ${parsed.snapshotPath} because generated contract contains ${diff.breakingCount} breaking change(s) against existing snapshot:`,
					);
					printDiffReport(committedDoc, generated);
					process.exit(2);
				}
				if (diff.breakingCount > 0 && parsed.force) {
					console.warn(
						`Warning: Overwriting ${parsed.snapshotPath} with ${diff.breakingCount} breaking change(s) via --force approved exception.`,
					);
				}
			} catch (error) {
				console.error(
					`Failed to diff candidate against existing snapshot at ${parsed.snapshotPath}:`,
					error,
				);
				process.exit(2);
			}
		}
		fs.writeFileSync(parsed.snapshotPath, serialized, "utf8");
		console.log(`Wrote OpenAPI snapshot to ${parsed.snapshotPath}`);
		return;
	}

	if (!fs.existsSync(parsed.snapshotPath)) {
		console.error(
			`OpenAPI snapshot missing at ${parsed.snapshotPath}. Run pnpm contract:write.`,
		);
		process.exit(1);
	}

	const committedRaw = fs.readFileSync(parsed.snapshotPath, "utf8");
	if (committedRaw === serialized) {
		console.log("OpenAPI contract snapshot is up to date.");
		return;
	}

	console.error(
		`OpenAPI contract drift detected against ${parsed.snapshotPath}:`,
	);
	try {
		const committedDoc = readJsonRecord(parsed.snapshotPath);
		const summary = printDiffReport(committedDoc, generated);
		if (summary.identical) {
			console.error(
				"  [FORMATTING] Key order or formatting differs from deterministic output.",
			);
		}
		if (summary.breakingCount > 0) {
			console.error(
				"Breaking v1 contract changes require advisor resolution or /api/v2.",
			);
			process.exit(2);
		}
	} catch (error) {
		console.error(
			`Committed snapshot could not be parsed as JSON: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
	console.error(
		"Run pnpm contract:write to regenerate additive snapshot changes.",
	);
	process.exit(1);
}

main();
