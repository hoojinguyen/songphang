import { JOB_NAMES, SendNotificationMailPayload } from "@songphang/contract";
import { formatNotificationText } from "@songphang/core";
import { findNotificationForImmediateMail } from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { immediateNotificationMail } from "../mail-templates.js";
import { createConsoleMailer, issueUnsubscribeToken } from "../mailer.js";
import { registerJob, type WorkerDeps } from "../queue.js";

export async function runSendNotificationMail(
	deps: WorkerDeps,
	notificationId: string,
): Promise<boolean> {
	const row = await findNotificationForImmediateMail(deps.db, notificationId);
	if (
		row === null ||
		row.readAt !== null ||
		!row.inGroup ||
		!row.emailImmediate ||
		row.emailVerifiedAt === null
	) {
		return false;
	}
	const { text: line, href: targetPath } = formatNotificationText({
		groupId: row.groupId,
		kind: row.kind,
		payload: row.payload,
	});
	const unsubscribeToken = await issueUnsubscribeToken(
		deps.db,
		row.userId,
		row.unsubscribeTokenHash,
	);
	const mail = immediateNotificationMail({
		webOrigin: deps.config.webOrigin,
		line,
		targetPath,
		unsubscribeToken,
	});
	const mailer = deps.mailer ?? createConsoleMailer();
	await mailer.send({
		to: row.email,
		subject: mail.subject,
		text: mail.text,
		headers: mail.headers,
		template: "notification_immediate",
		userId: row.userId,
	});
	return true;
}

export async function registerSendNotificationMailJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.sendNotificationMail,
		SendNotificationMailPayload,
		async (data, workerDeps) => {
			await runSendNotificationMail(workerDeps, data.notificationId);
		},
		deps,
	);
}
