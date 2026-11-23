import { createHash, createVerify, timingSafeEqual } from "node:crypto";
import { z } from "@hono/zod-openapi";
import { EmailAddress } from "@songphang/contract";
import type { Config } from "../../config.js";
import { AppError } from "../../errors.js";
import type { AppleKeySetProvider } from "./key-set.js";

const APPLE_ISSUER = "https://appleid.apple.com";
const MAX_CLOCK_SKEW_SECONDS = 60;

const JwtHeaderSchema = z.object({
	alg: z.literal("RS256"),
	kid: z.string().min(1).max(256),
});

const BaseApplePayloadSchema = z.object({
	iss: z.literal(APPLE_ISSUER),
	aud: z.string().min(1).max(255),
	sub: z.string().min(1).max(255),
	iat: z.number().int(),
	exp: z.number().int(),
});

const ApplePayloadSchema = BaseApplePayloadSchema.extend({
	nonce: z.string().regex(/^[0-9a-fA-F]{64}$/),
	email: EmailAddress.optional(),
	email_verified: z
		.union([
			z.literal(true),
			z.literal("true"),
			z.literal(false),
			z.literal("false"),
		])
		.optional(),
});

export type VerifiedAppleClaims = {
	sub: string;
	email?: string;
	emailVerified: boolean;
};

function parseBase64UrlJson(segment: string): unknown {
	if (!/^[A-Za-z0-9_-]+$/.test(segment)) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token is invalid",
		);
	}
	return JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
}

async function verifyAppleJwt<TSchema extends z.ZodTypeAny>(input: {
	token: string;
	config: Config;
	keySet: AppleKeySetProvider;
	now: Date;
	schema: TSchema;
}): Promise<z.infer<TSchema>> {
	if (!input.config.appleBundleId) {
		throw new AppError(404, "NOT_FOUND", "Apple sign-in is not configured");
	}
	const segments = input.token.split(".");
	const [headerSegment, payloadSegment, signatureSegment] = segments;
	if (
		segments.length !== 3 ||
		!headerSegment ||
		!payloadSegment ||
		!signatureSegment ||
		!/^[A-Za-z0-9_-]+$/.test(signatureSegment)
	) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token is invalid",
		);
	}

	let header: z.infer<typeof JwtHeaderSchema>;
	let rawPayload: unknown;
	try {
		header = JwtHeaderSchema.parse(parseBase64UrlJson(headerSegment));
		rawPayload = parseBase64UrlJson(payloadSegment);
	} catch {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token is invalid",
		);
	}

	const publicKey = await input.keySet.getKey(header.kid);
	if (publicKey === null) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple signing key was not found",
		);
	}

	const verifier = createVerify("RSA-SHA256");
	verifier.update(`${headerSegment}.${payloadSegment}`);
	verifier.end();
	const isSignatureValid = verifier.verify(
		publicKey,
		Buffer.from(signatureSegment, "base64url"),
	);
	if (!isSignatureValid) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token signature is invalid",
		);
	}

	const parsedPayload = input.schema.safeParse(rawPayload);
	if (!parsedPayload.success) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token claims are invalid",
		);
	}
	const claims = parsedPayload.data as z.infer<typeof BaseApplePayloadSchema>;
	if (claims.aud !== input.config.appleBundleId) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token audience is invalid",
		);
	}

	const nowSeconds = Math.floor(input.now.getTime() / 1000);
	if (claims.iat > nowSeconds + MAX_CLOCK_SKEW_SECONDS) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token issue time is invalid",
		);
	}
	if (claims.exp <= nowSeconds) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token has expired",
		);
	}

	return parsedPayload.data;
}

export async function verifyAppleIdentityToken(input: {
	identityToken: string;
	rawNonce: string;
	config: Config;
	keySet: AppleKeySetProvider;
	now: Date;
}): Promise<VerifiedAppleClaims> {
	const claims = await verifyAppleJwt({
		token: input.identityToken,
		config: input.config,
		keySet: input.keySet,
		now: input.now,
		schema: ApplePayloadSchema,
	});

	const expectedNonce = createHash("sha256")
		.update(input.rawNonce)
		.digest("hex");
	const actualNonce = claims.nonce.toLowerCase();
	if (
		!timingSafeEqual(
			Buffer.from(expectedNonce, "utf8"),
			Buffer.from(actualNonce, "utf8"),
		)
	) {
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Apple identity token nonce mismatch",
		);
	}

	const emailVerified =
		claims.email_verified === true || claims.email_verified === "true";

	return {
		sub: claims.sub,
		...(claims.email === undefined ? {} : { email: claims.email }),
		emailVerified,
	};
}

export async function verifyAppleExchangedIdToken(input: {
	idToken: string;
	config: Config;
	keySet: AppleKeySetProvider;
	now: Date;
}): Promise<{ sub: string }> {
	const claims = await verifyAppleJwt({
		token: input.idToken,
		config: input.config,
		keySet: input.keySet,
		now: input.now,
		schema: BaseApplePayloadSchema,
	});
	return { sub: claims.sub };
}
