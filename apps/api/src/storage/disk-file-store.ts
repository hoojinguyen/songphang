import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, unlink, writeFile } from "node:fs/promises";
import path from "node:path";
import type { FileStore } from "./file-store.js";

const STORAGE_KEY_RE = /^[0-9a-f-]{36}\/[0-9a-f-]{36}$/;

function resolveKeyPath(resolvedRoot: string, key: string): string {
	if (!STORAGE_KEY_RE.test(key)) {
		throw new Error("Invalid storage key");
	}
	const target = path.resolve(resolvedRoot, key);
	if (!target.startsWith(`${resolvedRoot}${path.sep}`)) {
		throw new Error("Invalid storage key path");
	}
	return target;
}

function isEnoent(error: unknown): boolean {
	return (
		typeof error === "object" &&
		error !== null &&
		"code" in error &&
		error.code === "ENOENT"
	);
}

export function diskFileStore(root: string): FileStore {
	const resolvedRoot = path.resolve(root);
	return {
		async put(key, bytes) {
			const target = resolveKeyPath(resolvedRoot, key);
			const dir = path.dirname(target);
			await mkdir(dir, { recursive: true });
			const tmp = path.join(
				dir,
				`${path.basename(target)}.tmp-${randomUUID()}`,
			);
			try {
				await writeFile(tmp, bytes);
				await rename(tmp, target);
			} catch (error) {
				await unlink(tmp).catch(() => {});
				throw error;
			}
		},
		async get(key) {
			const target = resolveKeyPath(resolvedRoot, key);
			try {
				const buf = await readFile(target);
				return new Uint8Array(buf);
			} catch (error) {
				if (isEnoent(error)) return null;
				throw error;
			}
		},
		async delete(key) {
			const target = resolveKeyPath(resolvedRoot, key);
			try {
				await unlink(target);
			} catch (error) {
				if (isEnoent(error)) return;
				throw error;
			}
		},
	};
}
