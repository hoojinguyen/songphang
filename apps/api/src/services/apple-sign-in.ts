import { randomUUID } from "node:crypto";
import { type AppleSignInRequest, UserDto } from "@songphang/contract";
import {
	clearAppleOperation,
	clearExpiredConflictingAppleExchanges,
	findAccountByEmail,
	findAppleIdentity,
	findAppleOperation,
	findUserAppleIdentity,
	findUserById,
	hasAppleExchange,
	hasRecentAppleDeletion,
	insertAccount,
	insertAppleIdentity,
	lockAccount,
	lockAppleOperation,
	pruneExpiredAppleOperations,
	saveAppleOperation,
	updateAppleProviderSecret,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { createAppleKeySetProvider } from "../auth/apple/key-set.js";
import { encryptSecret } from "../auth/apple/secret-box.js";
import {
	AppleTokenAdapterError,
	type AppleTokenExchangeResult,
	createAppleTokenAdapter,
} from "../auth/apple/token-adapter.js";
import {
	type VerifiedAppleClaims,
	verifyAppleExchangedIdToken,
	verifyAppleIdentityToken,
} from "../auth/apple/verify.js";
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
	const verificationDeadline = performance.now() + 30_000;
	const keySet =
		deps.appleKeySet ?? createAppleKeySetProvider(deps.config, deps.now);
	let claims: VerifiedAppleClaims;
	try {
		claims = await verifyAppleIdentityToken({
			identityToken: input.request.identityToken,
			rawNonce: input.request.rawNonce,
			config: deps.config,
			keySet,
			now: deps.now(),
		});
	} catch (error) {
		if (error instanceof AppError) {
			throw error;
		}
		console.warn(
			JSON.stringify({
				event: "apple.verify_identity_token.failed",
				category: error instanceof Error ? error.name : "unknown",
			}),
		);
		throw new AppError(
			503,
			"APPLE_REVOCATION_FAILED",
			"Could not verify Apple identity token with upstream provider",
		);
	}

	if (deps.config.appleProvider === "apple" && !deps.config.dataEncryptionKey) {
		throw new AppError(
			503,
			"APPLE_REVOCATION_FAILED",
			"Apple credential encryption key is missing",
		);
	}
	await pruneExpiredAppleOperations(deps.db);
	const operationKey = `exchange:${claims.sub}`;
	const owner = randomUUID();
	const hadPendingExchange = await deps.db.transaction(async (transaction) => {
		await lockAppleOperation(transaction, operationKey);
		if (claims.email)
			await lockAppleOperation(transaction, `email:${claims.email}`);
		const identityHint = await findAppleIdentity(transaction, claims.sub);
		const accountHint =
			identityHint === null && claims.email
				? await findAccountByEmail(transaction, claims.email)
				: null;
		const accountId = identityHint?.userId ?? accountHint?.id;
		if (
			accountId !== undefined &&
			(await lockAccount(transaction, accountId)).length === 0
		) {
			throw new AppError(403, "FORBIDDEN", "Account is undergoing deletion");
		}
		if (performance.now() >= verificationDeadline) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Apple sign-in verification timed out",
			);
		}
		const existingIdentity = await findAppleIdentity(transaction, claims.sub);
		if (await hasRecentAppleDeletion(transaction, claims.sub, claims.email)) {
			throw new AppError(
				403,
				"FORBIDDEN",
				"Apple account was recently deleted",
			);
		}
		if (accountId !== undefined) {
			const linked = await findUserAppleIdentity(transaction, accountId);
			if (linked?.providerSubject && linked.providerSubject !== claims.sub) {
				throw new AppError(
					403,
					"FORBIDDEN",
					"Account already has an Apple identity",
				);
			}
			if (linked?.providerSubject === claims.sub) {
				await clearExpiredConflictingAppleExchanges(
					transaction,
					accountId,
					claims.email,
					claims.sub,
				);
			}
		}
		if (
			existingIdentity?.providerSecret?.startsWith("REVOKING:") ||
			existingIdentity?.providerSecret?.startsWith(
				"APPLE_REVOCATION_COMPLETED:",
			)
		) {
			throw new AppError(403, "FORBIDDEN", "Account is undergoing deletion");
		}
		if (existingIdentity === null) {
			if (!claims.email || !claims.emailVerified) {
				throw new AppError(
					401,
					"INVALID_CREDENTIALS",
					"Apple identity token requires a verified email on first sign-in",
				);
			}
			const existingAccount = await findAccountByEmail(
				transaction,
				claims.email,
			);
			if (existingAccount && existingAccount.emailVerifiedAt === null) {
				throw new AppError(
					403,
					"EMAIL_NOT_VERIFIED",
					"Existing password account must verify email before linking Apple sign-in",
				);
			}
		}

		if (
			await hasAppleExchange(transaction, accountId, claims.email, operationKey)
		) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Another Apple sign-in is pending for this account",
			);
		}

		const previous = await findAppleOperation(transaction, operationKey);
		if (previous && previous.expiresAt > new Date()) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Apple sign-in is already in progress",
			);
		}
		await saveAppleOperation(transaction, {
			key: operationKey,
			owner,
			userId: accountId,
			email: claims.email,
			expiresAt: new Date(Date.now() + 120_000),
		});
		return previous !== null;
	});

	try {
		const adapter =
			deps.appleTokenAdapter ?? createAppleTokenAdapter(deps.config, deps.now);
		let exchanged: AppleTokenExchangeResult;
		try {
			exchanged = await adapter.exchangeAuthorizationCode(
				input.request.authorizationCode,
			);
		} catch (error) {
			if (error instanceof AppError) {
				throw error;
			}
			if (
				!hadPendingExchange &&
				error instanceof AppleTokenAdapterError &&
				error.category.startsWith("rejected:") &&
				error.category !== "rejected:unknown"
			) {
				await clearAppleOperation(deps.db, operationKey, owner);
			}
			const category =
				error instanceof AppleTokenAdapterError
					? error.category
					: error instanceof Error
						? error.name === "TimeoutError"
							? "timeout"
							: "unknown"
						: "unknown";
			console.warn(
				JSON.stringify({
					event: "apple.token_exchange.failed",
					category,
					operation: "exchangeAuthorizationCode",
				}),
			);
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Could not complete Apple token exchange",
			);
		}

		if (exchanged.idToken !== undefined) {
			let exchangedClaims: { sub: string };
			try {
				exchangedClaims = await verifyAppleExchangedIdToken({
					idToken: exchanged.idToken,
					config: deps.config,
					keySet,
					now: deps.now(),
				});
			} catch (error) {
				if (error instanceof AppError) {
					throw error;
				}
				console.warn(
					JSON.stringify({
						event: "apple.verify_exchanged_token.failed",
						category: error instanceof Error ? error.name : "unknown",
					}),
				);
				throw new AppError(
					503,
					"APPLE_REVOCATION_FAILED",
					"Could not verify Apple exchanged identity token with upstream provider",
				);
			}
			if (exchangedClaims.sub !== claims.sub) {
				throw new AppError(
					401,
					"INVALID_CREDENTIALS",
					"Apple authorization identity mismatch",
				);
			}
		} else if (exchanged.subject !== undefined) {
			if (exchanged.subject !== claims.sub) {
				throw new AppError(
					401,
					"INVALID_CREDENTIALS",
					"Apple authorization identity mismatch",
				);
			}
		} else if (deps.config.appleProvider === "apple") {
			throw new AppError(
				401,
				"INVALID_CREDENTIALS",
				"Apple token exchange missing identity token",
			);
		}

		let encryptedSecret: string | null = null;
		if (deps.config.appleProvider === "apple") {
			if (!exchanged.refreshToken || !deps.config.dataEncryptionKey) {
				throw new AppError(
					503,
					"APPLE_REVOCATION_FAILED",
					"Could not complete Apple token exchange",
				);
			}
			encryptedSecret = encryptSecret(
				exchanged.refreshToken,
				deps.config.dataEncryptionKey,
			);
		}

		return await deps.db.transaction(async (transaction) => {
			await lockAppleOperation(transaction, operationKey);
			const operation = await findAppleOperation(transaction, operationKey);
			if (operation?.owner !== owner) {
				throw new AppError(
					503,
					"APPLE_REVOCATION_FAILED",
					"Apple sign-in reservation changed",
				);
			}

			const now = deps.now();
			const known = await findAppleIdentity(transaction, claims.sub);
			let userId: string;

			if (known !== null) {
				if ((await lockAccount(transaction, known.userId)).length === 0) {
					throw new AppError(
						403,
						"FORBIDDEN",
						"Account is undergoing deletion",
					);
				}
				const current = await findAppleIdentity(transaction, claims.sub);
				if (
					current?.userId !== known.userId ||
					current.providerSecret?.startsWith("REVOKING:") ||
					current.providerSecret?.startsWith("APPLE_REVOCATION_COMPLETED:")
				) {
					throw new AppError(
						403,
						"FORBIDDEN",
						"Account is undergoing deletion",
					);
				}
				userId = known.userId;
				if (encryptedSecret !== null) {
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
				...(input.userAgent === undefined
					? {}
					: { userAgent: input.userAgent }),
			});
			await clearAppleOperation(transaction, operationKey, owner);
			return { session, user: UserDto.parse(userRow) };
		});
	} catch (error) {
		if (
			!hadPendingExchange &&
			error instanceof AppError &&
			error.status < 500
		) {
			await clearAppleOperation(deps.db, operationKey, owner);
		}
		throw error;
	}
}
