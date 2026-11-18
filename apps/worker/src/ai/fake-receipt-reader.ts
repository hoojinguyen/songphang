import { readFile } from "node:fs/promises";
import path from "node:path";
import { ReceiptReading } from "@songphang/contract";
import { z } from "zod";
import type { FakeReceiptFixture } from "../config.js";
import type {
	ReceiptReader,
	ReceiptReaderInput,
	ReceiptReaderOutput,
} from "./receipt-reader.js";

const FIXTURES_DIR = path.resolve(
	import.meta.dirname,
	"../../fixtures/receipts",
);

const MANIFEST_ENTRY_SCHEMA = z.object({
	key: z.enum(["clean", "tax-service", "mismatch", "not-a-receipt"]),
	sha256: z.string().min(1),
	reading: z.string().min(1),
});

const MANIFEST_SCHEMA = z.array(MANIFEST_ENTRY_SCHEMA);

const FALLBACK_READING: z.input<typeof ReceiptReading> = {
	merchant: null,
	occurredOn: null,
	items: [
		{ name: "Món 1", quantity: 1, amount: 100000 },
		{ name: "Món 2", quantity: 1, amount: 50000 },
		{ name: "Món 3", quantity: 1, amount: 30000 },
	],
	extras: [],
	total: 180000,
};

async function loadFixtureReading(
	sha256: string,
	fixtureOverride?: FakeReceiptFixture,
): Promise<ReceiptReading> {
	const manifestRaw = await readFile(
		path.join(FIXTURES_DIR, "manifest.json"),
		"utf8",
	);
	const manifest = MANIFEST_SCHEMA.parse(JSON.parse(manifestRaw));

	const entry =
		fixtureOverride && fixtureOverride !== "default"
			? manifest.find((item) => item.key === fixtureOverride)
			: manifest.find((item) => item.sha256 === sha256);

	if (!entry) {
		return ReceiptReading.parse(FALLBACK_READING);
	}

	const readingRaw = await readFile(
		path.join(FIXTURES_DIR, entry.reading),
		"utf8",
	);
	return ReceiptReading.parse(JSON.parse(readingRaw));
}

export function createFakeReceiptReader(
	fixtureOverride?: FakeReceiptFixture,
): ReceiptReader {
	return {
		async readReceipt(input: ReceiptReaderInput): Promise<ReceiptReaderOutput> {
			const reading = await loadFixtureReading(input.sha256, fixtureOverride);
			return {
				reading,
				model: "fake-receipt-v1",
				inputTokens: 0,
				outputTokens: 0,
			};
		},
	};
}
