const MAX_SIDE_PX = 2000;
const JPEG_QUALITY = 0.85;

export async function prepareImage(file: File): Promise<Blob> {
	const bitmap = await createImageBitmap(file, {
		imageOrientation: "from-image",
	});
	try {
		const longest = Math.max(bitmap.width, bitmap.height);
		if (longest <= 0) {
			throw new Error("Invalid image dimensions");
		}
		const scale = longest > MAX_SIDE_PX ? MAX_SIDE_PX / longest : 1;
		const width = Math.max(1, Math.round(bitmap.width * scale));
		const height = Math.max(1, Math.round(bitmap.height * scale));
		const canvas = document.createElement("canvas");
		canvas.width = width;
		canvas.height = height;
		const ctx = canvas.getContext("2d");
		if (!ctx) {
			throw new Error("Canvas 2D context unavailable");
		}
		ctx.drawImage(bitmap, 0, 0, width, height);
		return await new Promise<Blob>((resolve, reject) => {
			canvas.toBlob(
				(blob) => {
					if (blob) resolve(blob);
					else reject(new Error("Image encoding failed"));
				},
				"image/jpeg",
				JPEG_QUALITY,
			);
		});
	} finally {
		bitmap.close();
	}
}
