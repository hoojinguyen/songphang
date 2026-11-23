import { createPrivateKey } from "node:crypto";

export function validateEcP256PrivateKey(
	rawPem: string,
	fieldPath: string,
	context: {
		addIssue: (issue: {
			code: "custom";
			path: (string | number)[];
			message: string;
		}) => void;
	},
): void {
	try {
		const key = createPrivateKey(rawPem);
		if (key.asymmetricKeyType !== "ec") {
			context.addIssue({
				code: "custom",
				path: [fieldPath],
				message: `${fieldPath} must be an EC private key`,
			});
		} else {
			const curve = key.asymmetricKeyDetails?.namedCurve;
			if (curve !== "prime256v1" && curve !== "p256") {
				context.addIssue({
					code: "custom",
					path: [fieldPath],
					message: `${fieldPath} must use the prime256v1 (P-256) curve, got ${curve ?? "unknown"}`,
				});
			}
		}
	} catch (error) {
		const message =
			error instanceof Error ? error.message : "invalid key format";
		context.addIssue({
			code: "custom",
			path: [fieldPath],
			message: `${fieldPath} could not be parsed as a private key: ${message}`,
		});
	}
}
