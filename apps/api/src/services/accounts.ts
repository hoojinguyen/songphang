import type {
	LoginRequest,
	RegisterRequest,
	UserDto,
} from "@songphang/contract";
import {
	findAccountByEmail,
	insertAccount,
	insertIdentity,
	verifyAccountEmail,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { consumeToken, issueToken } from "../auth/one-time-tokens.js";
import {
	checkNewPassword,
	DUMMY_PASSWORD_HASH,
	hashPassword,
	verifyPassword,
} from "../auth/passwords.js";
import { createSession } from "../auth/sessions.js";
import { AppError } from "../errors.js";
import { accountExistsMail, verificationMail } from "../mail-templates.js";
export function requireStrongPassword(password: string): void {
	const reason = checkNewPassword(password);
	if (reason !== "ok")
		throw new AppError(
			400,
			"WEAK_PASSWORD",
			"Password does not meet requirements",
			{ reason },
		);
}
export async function registerAccount(
	deps: AppDeps,
	request: RegisterRequest,
): Promise<void> {
	requireStrongPassword(request.password);
	const passwordHash = await hashPassword(request.password);
	const now = deps.now();
	const mail = await deps.db.transaction(async (transaction) => {
		const existing = await findAccountByEmail(transaction, request.email);
		if (existing !== null)
			return accountExistsMail(`${deps.config.webOrigin}/login`);
		const account = await insertAccount(transaction, {
			email: request.email,
			name: request.name,
			createdAt: now,
			updatedAt: now,
		});
		if (account === null)
			return accountExistsMail(`${deps.config.webOrigin}/login`);
		await insertIdentity(transaction, {
			userId: account.id,
			provider: "password",
			passwordHash,
			createdAt: now,
		});
		const token = await issueToken(transaction, {
			userId: account.id,
			purpose: "verify_email",
			now,
		});
		return verificationMail(
			request.name,
			`${deps.config.webOrigin}/verify-email?token=${token}`,
		);
	});
	await deps.mailer.send({ to: request.email, ...mail });
}
export async function loginAccount(
	deps: AppDeps,
	input: { request: LoginRequest; userAgent?: string },
) {
	const account = await findAccountByEmail(deps.db, input.request.email);
	const matches = await verifyPassword(
		input.request.password,
		account?.passwordHash ?? DUMMY_PASSWORD_HASH,
	);
	if (!matches || account === null || account.passwordHash === null)
		throw new AppError(
			401,
			"INVALID_CREDENTIALS",
			"Email or password is incorrect",
		);
	return createSession(deps.db, {
		userId: account.id,
		now: deps.now(),
		...(input.userAgent === undefined ? {} : { userAgent: input.userAgent }),
	});
}
export async function verifyEmail(deps: AppDeps, token: string): Promise<void> {
	await deps.db.transaction(async (transaction) => {
		const now = deps.now();
		const userId = await consumeToken(transaction, {
			token,
			purpose: "verify_email",
			now,
		});
		if (userId === null)
			throw new AppError(400, "TOKEN_INVALID", "Token is invalid or expired");
		await verifyAccountEmail(transaction, { userId, now });
	});
}
export async function resendVerification(
	deps: AppDeps,
	user: UserDto,
): Promise<void> {
	if (user.emailVerified) return;
	const token = await issueToken(deps.db, {
		userId: user.id,
		purpose: "verify_email",
		now: deps.now(),
	});
	await deps.mailer.send({
		to: user.email,
		...verificationMail(
			user.name,
			`${deps.config.webOrigin}/verify-email?token=${token}`,
		),
	});
}
export function getProviders(deps: AppDeps) {
	return {
		google: Boolean(
			deps.config.googleClientId && deps.config.googleClientSecret,
		),
		devLogin: deps.config.devLogin,
	};
}
