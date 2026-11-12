import type {
	ChangePasswordRequest,
	DeleteAccountRequest,
	ForgotPasswordRequest,
	ResetPasswordRequest,
	UserDto,
} from "@songphang/contract";
import {
	countOwnedGroups,
	deleteAccountRow,
	deleteUserSessions,
	findAccountByEmail,
	findAccountById,
	lockAccount,
	updatePasswordHash,
	verifyAccountEmail,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
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
	await deps.db.transaction(async (transaction) => {
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
	});
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
	await deps.db.transaction(async (transaction) => {
		await lockAccount(transaction, input.user.id);
		const groupCount = await countOwnedGroups(transaction, input.user.id);
		if (groupCount > 0)
			throw new AppError(
				422,
				"OWNER_REQUIRED",
				"Transfer or delete owned groups first",
				{ groupCount },
			);
		await deleteAccountRow(transaction, input.user.id);
	});
}
