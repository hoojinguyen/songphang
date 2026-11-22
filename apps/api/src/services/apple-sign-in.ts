import { type AppleSignInRequest, UserDto } from "@songphang/contract";
import {
	findAccountByEmail,
	findAppleIdentity,
	findUserById,
	insertAccount,
	insertAppleIdentity,
	lockAccount,
	updateAppleProviderSecret,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { createAppleKeySetProvider } from "../auth/apple/key-set.js";
import { encryptSecret } from "../auth/apple/secret-box.js";
import { createAppleTokenAdapter } from "../auth/apple/token-adapter.js";
import { verifyAppleIdentityToken } from "../auth/apple/verify.js";
import { createSession } from "../auth/sessions.js";
import { AppError } from "../errors.js";

function fallbackAppleName(
	requestedName: string | undefined,
	email: string,
): string {
	const trimmed = requestedName?.trim();
	if (trimmed && trimmed.length >= 1) {
		return trimmed.slice(0, 50);
	}
	const localPart = email.split("@")[0]?.trim();
	if (localPart && localPart.length >= 1) {
		return localPart.slice(0, 50);
	}
	return "Người dùng Apple";
}

export async function appleSignIn(
	deps: AppDeps,
	input: {
		request: AppleSignInRequest;
		userAgent?: string;
	},
) {
	if (!deps.config.appleProvider) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const keySet =
		deps.appleKeySet ?? createAppleKeySetProvider(deps.config, deps.now);
	const claims = await verifyAppleIdentityToken({
		identityToken: input.request.identityToken,
		rawNonce: input.request.rawNonce,
		config: deps.config,
		keySet,
		now: deps.now(),
	});

	const existingIdentity = await findAppleIdentity(deps.db, claims.sub);
	if (existingIdentity === null) {
		if (!claims.email || !claims.emailVerified) {
			throw new AppError(
				401,
				"INVALID_CREDENTIALS",
				"Apple identity token requires a verified email on first sign-in",
			);
		}
		const existingAccount = await findAccountByEmail(deps.db, claims.email);
		if (existingAccount && existingAccount.emailVerifiedAt === null) {
			throw new AppError(
				403,
				"EMAIL_NOT_VERIFIED",
				"Existing password account must verify email before linking Apple sign-in",
			);
		}
	}

	let encryptedSecret: string | null = null;
	const needsExchange =
		deps.config.appleProvider === "apple" &&
		(existingIdentity === null || existingIdentity.providerSecret === null);
	if (needsExchange) {
		if (!deps.config.dataEncryptionKey) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Apple credential encryption key is missing",
			);
		}
		try {
			const adapter =
				deps.appleTokenAdapter ??
				createAppleTokenAdapter(deps.config, deps.now);
			const refreshToken = await adapter.exchangeAuthorizationCode(
				input.request.authorizationCode,
			);
			if (!refreshToken) {
				throw new Error("Empty Apple refresh token");
			}
			encryptedSecret = encryptSecret(
				refreshToken,
				deps.config.dataEncryptionKey,
			);
		} catch {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Could not complete Apple token exchange",
			);
		}
	}

	return deps.db.transaction(async (transaction) => {
		const now = deps.now();
		const known = await findAppleIdentity(transaction, claims.sub);
		let userId: string;

		if (known !== null) {
			userId = known.userId;
			if (encryptedSecret !== null && known.providerSecret === null) {
				await updateAppleProviderSecret(transaction, {
					userId,
					subject: claims.sub,
					providerSecret: encryptedSecret,
				});
			}
		} else {
			const email = claims.email;
			if (!email || !claims.emailVerified) {
				throw new AppError(
					401,
					"INVALID_CREDENTIALS",
					"Apple identity token requires a verified email",
				);
			}
			let account = await findAccountByEmail(transaction, email);
			if (account && account.emailVerifiedAt === null) {
				throw new AppError(
					403,
					"EMAIL_NOT_VERIFIED",
					"Existing password account must verify email before linking Apple sign-in",
				);
			}
			if (!account) {
				await insertAccount(transaction, {
					email,
					name: fallbackAppleName(input.request.name, email),
					avatarUrl: null,
					emailVerifiedAt: now,
					createdAt: now,
					updatedAt: now,
				});
				account = await findAccountByEmail(transaction, email);
			}
			if (!account) {
				throw new Error("Apple account creation failed");
			}
			await lockAccount(transaction, account.id);
			const current = await findAccountByEmail(transaction, email);
			if (!current || current.emailVerifiedAt === null) {
				throw new AppError(
					403,
					"EMAIL_NOT_VERIFIED",
					"Existing password account must verify email before linking Apple sign-in",
				);
			}
			await insertAppleIdentity(transaction, {
				userId: current.id,
				subject: claims.sub,
				providerSecret: encryptedSecret,
				now,
			});
			const identity = await findAppleIdentity(transaction, claims.sub);
			if (!identity) {
				throw new Error("Apple identity association failed");
			}
			userId = identity.userId;
		}

		const userRow = await findUserById(transaction, userId);
		if (userRow === null) {
			throw new AppError(404, "NOT_FOUND", "User not found");
		}
		const session = await createSession(transaction, {
			userId,
			now,
			client: input.request.client,
			deviceName: input.request.deviceName,
			...(input.userAgent === undefined ? {} : { userAgent: input.userAgent }),
		});
		return { session, user: UserDto.parse(userRow) };
	});
}
