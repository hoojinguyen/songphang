import { createHash, randomUUID } from "node:crypto";
import type {
	ChangePasswordRequest,
	DeleteAccountRequest,
	ForgotPasswordRequest,
	ResetPasswordRequest,
	UserDto,
} from "@songphang/contract";
import {
	clearAppleOperation,
	clearExpiredConflictingAppleExchanges,
	countOwnedGroups,
	deleteAccountRow,
	deleteUserSessions,
	findAccountByEmail,
	findAccountById,
	findAppleOperation,
	findUserAppleIdentity,
	hasAppleExchange,
	listUserGroups,
	lockAccount,
	lockAppleOperation,
	recordAppleDeletion,
	saveAppleOperation,
	updateAppleProviderSecret,
	updatePasswordHash,
	verifyAccountEmail,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { decryptSecret } from "../auth/apple/secret-box.js";
import {
	AppleTokenAdapterError,
	createAppleTokenAdapter,
} from "../auth/apple/token-adapter.js";
import { consumeToken, issueToken } from "../auth/one-time-tokens.js";
import { hashPassword, verifyPassword } from "../auth/passwords.js";
import { hashSessionToken } from "../auth/sessions.js";
import { AppError } from "../errors.js";
import { resetPasswordMail } from "../mail-templates.js";
import { requireStrongPassword } from "./accounts.js";
export async function forgotPassword(
	deps: AppDeps,
	request: ForgotPasswordRequest,
): Promise<void> {
	const account = await findAccountByEmail(deps.db, request.email);
	if (account?.passwordHash === null || account === null) return;
	const token = await issueToken(deps.db, {
		userId: account.id,
		purpose: "reset_password",
		now: deps.now(),
	});
	await deps.mailer.send({
		to: account.email,
		...resetPasswordMail(
			`${deps.config.webOrigin}/reset-password?token=${token}`,
		),
	});
}
export async function resetPassword(
	deps: AppDeps,
	request: ResetPasswordRequest,
): Promise<void> {
	requireStrongPassword(request.password);
	const passwordHash = await hashPassword(request.password);
	const userId = await deps.db.transaction(async (transaction) => {
		const now = deps.now();
		const userId = await consumeToken(transaction, {
			token: request.token,
			purpose: "reset_password",
			now,
		});
		if (userId === null)
			throw new AppError(400, "TOKEN_INVALID", "Token is invalid or expired");
		await updatePasswordHash(transaction, { userId, passwordHash });
		await verifyAccountEmail(transaction, { userId, now });
		await deleteUserSessions(transaction, { userId });
		return userId;
	});
	deps.events.revokeUserSessions(userId);
}
export async function changePassword(
	deps: AppDeps,
	input: {
		userId: string;
		sessionToken: string;
		request: ChangePasswordRequest;
	},
): Promise<void> {
	await deps.db.transaction(async (transaction) => {
		await lockAccount(transaction, input.userId);
		const account = await findAccountById(transaction, input.userId);
		if (account === null || account.passwordHash === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (
			!(await verifyPassword(
				input.request.currentPassword,
				account.passwordHash,
			))
		)
			throw new AppError(
				401,
				"INVALID_CREDENTIALS",
				"Email or password is incorrect",
			);
		requireStrongPassword(input.request.newPassword);
		const passwordHash = await hashPassword(input.request.newPassword);
		await updatePasswordHash(transaction, {
			userId: input.userId,
			passwordHash,
		});
		if (input.request.revokeOtherSessions)
			await deleteUserSessions(transaction, {
				userId: input.userId,
				keepTokenHash: hashSessionToken(input.sessionToken),
			});
	});
	if (input.request.revokeOtherSessions)
		deps.events.revokeUserSessions(
			input.userId,
			hashSessionToken(input.sessionToken),
		);
}
export async function deleteAccount(
	deps: AppDeps,
	input: { user: UserDto; request: DeleteAccountRequest },
): Promise<void> {
	if (input.request.email !== input.user.email.toLowerCase())
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Email confirmation does not match",
		);

	// Phase 1: Pre-check ownership and mark Apple identity revoking inside transaction
	const {
		appleIdentity,
		grantHash,
		needsRevocation,
		refreshToken,
		deletedGroups,
	} = await deps.db.transaction(async (tx) => {
		await lockAppleOperation(tx, `email:${input.user.email.toLowerCase()}`);
		await lockAccount(tx, input.user.id);
		const identity = await findUserAppleIdentity(tx, input.user.id);
		if (identity?.providerSubject) {
			await clearExpiredConflictingAppleExchanges(
				tx,
				input.user.id,
				input.user.email,
				identity.providerSubject,
			);
		}
		if (
			await hasAppleExchange(tx, input.user.id, input.user.email.toLowerCase())
		) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Apple sign-in is still pending",
			);
		}
		const ownedGroups = await countOwnedGroups(tx, input.user.id);
		if (ownedGroups > 0) {
			throw new AppError(
				422,
				"OWNER_REQUIRED",
				"Transfer or delete owned groups first",
				{ groupCount: ownedGroups },
			);
		}

		if (identity === null) {
			const groups = await listUserGroups(tx, input.user.id);
			await recordAppleDeletion(tx, input.user.email);
			await deleteAccountRow(tx, input.user.id);
			return {
				deletedGroups: groups,
				appleIdentity: null,
				grantHash: null,
				needsRevocation: false,
				refreshToken: null,
			};
		}

		if (!deps.config.appleProvider) {
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Apple provider is disabled; cannot revoke Apple authorization",
			);
		}

		const rawSecret = identity.providerSecret ?? "";
		if (rawSecret.startsWith("APPLE_REVOCATION_COMPLETED:")) {
			return {
				deletedGroups: null,
				appleIdentity: identity,
				grantHash: null,
				needsRevocation: false,
				refreshToken: null,
			};
		}

		const actualSecret = rawSecret.startsWith("REVOKING:")
			? rawSecret.slice("REVOKING:".length)
			: rawSecret;
		const hash = createHash("sha256").update(actualSecret).digest("hex");

		let tokenToRevoke: string | null = null;
		if (deps.config.appleProvider === "apple") {
			if (!actualSecret || !deps.config.dataEncryptionKey) {
				throw new AppError(
					503,
					"APPLE_REVOCATION_FAILED",
					"Missing Apple revocation material",
				);
			}
			try {
				tokenToRevoke = decryptSecret(
					actualSecret,
					deps.config.dataEncryptionKey,
				);
			} catch {
				throw new AppError(
					503,
					"APPLE_REVOCATION_FAILED",
					"Could not decrypt Apple revocation material",
				);
			}
		}

		if (identity.providerSubject) {
			await updateAppleProviderSecret(tx, {
				userId: input.user.id,
				subject: identity.providerSubject,
				providerSecret: `REVOKING:${actualSecret}`,
			});
		}

		return {
			deletedGroups: null,
			appleIdentity: identity,
			grantHash: hash,
			needsRevocation: true,
			refreshToken: tokenToRevoke,
		};
	});

	// Phase 2: Call Apple adapter to revoke token (if needed)
	if (needsRevocation && appleIdentity !== null) {
		const adapter =
			deps.appleTokenAdapter ?? createAppleTokenAdapter(deps.config, deps.now);
		const key = `revoke:${input.user.id}`;
		const owner = randomUUID();
		let claimed = false;
		try {
			const subject = await deps.db.transaction(async (tx) => {
				await lockAppleOperation(tx, key);
				const current = await findUserAppleIdentity(tx, input.user.id);
				if (
					current === null ||
					current.providerSecret?.startsWith("APPLE_REVOCATION_COMPLETED:")
				)
					return null;
				const expected = appleIdentity.providerSecret?.startsWith("REVOKING:")
					? appleIdentity.providerSecret
					: `REVOKING:${appleIdentity.providerSecret ?? ""}`;
				if (
					current.providerSecret !== expected ||
					!current.providerSubject ||
					!grantHash
				) {
					throw new Error("Apple grant changed during deletion");
				}
				const previous = await findAppleOperation(tx, key);
				if (previous && previous.expiresAt > new Date()) {
					throw new Error("Apple revocation is already in progress");
				}
				await saveAppleOperation(tx, {
					key,
					owner,
					expiresAt: new Date(Date.now() + 30_000),
				});
				return current.providerSubject;
			});
			if (subject !== null) {
				claimed = true;
				await adapter.revokeRefreshToken({
					refreshToken,
					userId: input.user.id,
				});
				await deps.db.transaction(async (tx) => {
					await lockAppleOperation(tx, key);
					if ((await findAppleOperation(tx, key))?.owner !== owner) {
						throw new Error("Apple revocation reservation changed");
					}
					await updateAppleProviderSecret(tx, {
						userId: input.user.id,
						subject,
						providerSecret: `APPLE_REVOCATION_COMPLETED:${grantHash}`,
					});
					await clearAppleOperation(tx, key, owner);
				});
			}
		} catch (error) {
			if (claimed) {
				try {
					await clearAppleOperation(deps.db, key, owner);
				} catch {
					console.warn(
						JSON.stringify({ event: "apple.revoke.cleanup_failed" }),
					);
				}
			}

			const category =
				error instanceof AppleTokenAdapterError
					? error.category
					: error instanceof Error
						? error.name
						: "unknown";
			console.warn(
				JSON.stringify({
					event: "apple.revoke.failed",
					category,
					operation: "revokeRefreshToken",
				}),
			);
			throw new AppError(
				503,
				"APPLE_REVOCATION_FAILED",
				"Could not revoke Apple authorization",
			);
		}
	}

	// Phase 3: Final deletion transaction
	const groups =
		deletedGroups ??
		(await deps.db.transaction(async (transaction) => {
			await lockAppleOperation(
				transaction,
				`email:${input.user.email.toLowerCase()}`,
			);
			if ((await lockAccount(transaction, input.user.id)).length === 0)
				return [];
			const groupCount = await countOwnedGroups(transaction, input.user.id);
			if (groupCount > 0)
				throw new AppError(
					422,
					"OWNER_REQUIRED",
					"Transfer or delete owned groups first",
					{ groupCount },
				);
			const userGroups = await listUserGroups(transaction, input.user.id);
			await recordAppleDeletion(
				transaction,
				input.user.email,
				appleIdentity?.providerSubject,
			);
			await deleteAccountRow(transaction, input.user.id);
			return userGroups;
		}));

	deps.events.revokeUserSessions(input.user.id);
	for (const group of groups) {
		deps.events.publishRemoved(group.id, input.user.id);
		deps.events.publishChanged(group.id, [
			"users",
			"members",
			"group",
			"activity",
		]);
	}
}
