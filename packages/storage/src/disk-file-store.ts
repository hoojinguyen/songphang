import { randomUUID } from "node:crypto";
import {
	mkdir,
	readdir,
	readFile,
	rename,
	rmdir,
	stat,
	unlink,
	writeFile,
} from "node:fs/promises";
import path from "node:path";
import type { FileStore, StoredEntry } from "./file-store.js";

const UUID_DIR_RE = /^[0-9a-f-]{36}$/;
const STORAGE_KEY_RE = /^[0-9a-f-]{36}\/[0-9a-f-]{36}$/;
const SAFE_FILE_NAME_RE = /^[0-9a-f-]{36}(\.tmp-[0-9a-f-]{36})?$/;

function resolveInsideRoot(resolvedRoot: string, relative: string): string {
	const target = path.resolve(resolvedRoot, relative);
	if (!target.startsWith(`${resolvedRoot}${path.sep}`)) {
		throw new Error("Invalid storage key path");
	}
	return target;
}

function resolveKeyPath(resolvedRoot: string, key: string): string {
	if (!STORAGE_KEY_RE.test(key)) {
		throw new Error("Invalid storage key");
	}
	return resolveInsideRoot(resolvedRoot, key);
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
		async listGroupDirs() {
			try {
				const entries = await readdir(resolvedRoot, { withFileTypes: true });
				return entries
					.filter(
						(entry) => entry.isDirectory() && UUID_DIR_RE.test(entry.name),
					)
					.map((entry) => entry.name);
			} catch (error) {
				if (isEnoent(error)) return [];
				throw error;
			}
		},
		async listGroupFiles(groupId) {
			if (!UUID_DIR_RE.test(groupId)) return [];
			const dir = resolveInsideRoot(resolvedRoot, groupId);
			try {
				const entries = await readdir(dir, { withFileTypes: true });
				const files: StoredEntry[] = [];
				for (const entry of entries) {
					if (!entry.isFile() || !SAFE_FILE_NAME_RE.test(entry.name)) continue;
					const fileStat = await stat(path.join(dir, entry.name)).catch(
						() => null,
					);
					if (fileStat) {
						files.push({ name: entry.name, mtimeMs: fileStat.mtimeMs });
					}
				}
				return files;
			} catch (error) {
				if (isEnoent(error)) return [];
				throw error;
			}
		},
		async deleteGroupFile(groupId, name) {
			if (!UUID_DIR_RE.test(groupId) || !SAFE_FILE_NAME_RE.test(name)) {
				throw new Error("Invalid storage entry");
			}
			const target = resolveInsideRoot(resolvedRoot, `${groupId}/${name}`);
			try {
				await unlink(target);
			} catch (error) {
				if (isEnoent(error)) return;
				throw error;
			}
		},
		async removeEmptyGroupDir(groupId) {
			if (!UUID_DIR_RE.test(groupId)) return;
			const dir = resolveInsideRoot(resolvedRoot, groupId);
			await rmdir(dir).catch(() => {});
		},
	};
}
