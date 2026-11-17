export type StoredEntry = {
	name: string;
	mtimeMs: number;
};

export interface FileStore {
	put(key: string, bytes: Uint8Array, contentType: string): Promise<void>;
	get(key: string): Promise<Uint8Array | null>;
	delete(key: string): Promise<void>;
	listGroupDirs(): Promise<string[]>;
	listGroupFiles(groupId: string): Promise<StoredEntry[]>;
	deleteGroupFile(groupId: string, name: string): Promise<void>;
	removeEmptyGroupDir(groupId: string): Promise<void>;
}
