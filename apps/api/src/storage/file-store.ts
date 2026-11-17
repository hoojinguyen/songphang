export interface FileStore {
	put(key: string, bytes: Uint8Array, contentType: string): Promise<void>;
	get(key: string): Promise<Uint8Array | null>;
	delete(key: string): Promise<void>;
}
