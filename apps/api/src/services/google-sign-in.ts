import {
	findAccountByEmail,
	findGoogleIdentity,
	insertAccount,
	insertGoogleIdentity,
	lockAccount,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { GoogleClaims } from "../auth/google.js";
import { createSession } from "../auth/sessions.js";
export async function resolveGoogleUserId(
	deps: AppDeps,
	input: GoogleClaims,
): Promise<{ kind: "google_unverified" } | { kind: "ok"; userId: string }> {
	const claims = GoogleClaims.parse(input);
	const userId = await deps.db.transaction(async (transaction) => {
		const known = await findGoogleIdentity(transaction, claims.sub);
		if (known) return known.userId;
		let account = await findAccountByEmail(transaction, claims.email);
		if (account && account.emailVerifiedAt === null) return null;
		if (!account) {
			const now = deps.now();
			await insertAccount(transaction, {
				email: claims.email,
				name: claims.name,
				avatarUrl: claims.picture ?? null,
				emailVerifiedAt: now,
				createdAt: now,
				updatedAt: now,
			});
			account = await findAccountByEmail(transaction, claims.email);
		}
		if (!account) throw new Error("Google account creation failed");
		await lockAccount(transaction, account.id);
		const current = await findAccountByEmail(transaction, claims.email);
		if (!current || current.emailVerifiedAt === null) return null;
		await insertGoogleIdentity(transaction, {
			userId: current.id,
			subject: claims.sub,
			now: deps.now(),
		});
		const identity = await findGoogleIdentity(transaction, claims.sub);
		if (!identity) throw new Error("Google identity association failed");
		return identity.userId;
	});
	if (userId === null) return { kind: "google_unverified" };
	return { kind: "ok", userId };
}

export async function googleSignIn(deps: AppDeps, input: GoogleClaims) {
	const resolved = await resolveGoogleUserId(deps, input);
	if (resolved.kind === "google_unverified") {
		return { kind: "google_unverified" } as const;
	}
	return {
		kind: "signed_in",
		session: await createSession(deps.db, {
			userId: resolved.userId,
			now: deps.now(),
		}),
	} as const;
}
