import { JOB_NAMES, SendDigestPayload } from "@songphang/contract";
import { formatNotificationText } from "@songphang/core";
import {
	getJobCheckpoint,
	listUnreadDigestNotifications,
	setJobCheckpoint,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { digestMail } from "../mail-templates.js";
import { createConsoleMailer, issueUnsubscribeToken } from "../mailer.js";
import { registerJob, type WorkerDeps } from "../queue.js";

const DIGEST_LINE_LIMIT = 20;

type DigestRow = Awaited<
	ReturnType<typeof listUnreadDigestNotifications>
>[number];

function payloadField(payload: unknown, key: string): string {
	if (typeof payload !== "object" || payload === null || Array.isArray(payload))
		return "";
	const record: Record<string, unknown> = Object.fromEntries(
		Object.entries(payload),
	);
	return typeof record[key] === "string" ? (record[key] ?? "") : "";
}

function buildUserDigestLines(rows: DigestRow[]): string[] {
	const byGroup = new Map<string, DigestRow[]>();
	for (const row of rows) {
		const groupList = byGroup.get(row.groupId);
		if (groupList) groupList.push(row);
		else byGroup.set(row.groupId, [row]);
	}
	const multiGroup = byGroup.size > 1;
	const lines: string[] = [];
	for (const groupRows of byGroup.values()) {
		const byTransaction = new Map<string, DigestRow[]>();
		for (const row of groupRows) {
			const txId = payloadField(row.payload, "transactionId");
			const bucketKey = txId ? `tx:${txId}` : `row:${row.id}`;
			const bucket = byTransaction.get(bucketKey);
			if (bucket) bucket.push(row);
			else byTransaction.set(bucketKey, [row]);
		}
		for (const txRows of byTransaction.values()) {
			const comments = txRows.filter((row) => row.kind === "comment_added");
			const others = txRows.filter((row) => row.kind !== "comment_added");
			for (const row of others) {
				const line = formatNotificationText({
					groupId: row.groupId,
					kind: row.kind,
					payload: row.payload,
				}).text;
				const groupName = payloadField(row.payload, "groupName");
				lines.push(multiGroup && groupName ? `${groupName} · ${line}` : line);
			}
			if (comments.length === 1 && comments[0]) {
				const row = comments[0];
				const line = formatNotificationText({
					groupId: row.groupId,
					kind: row.kind,
					payload: row.payload,
				}).text;
				const groupName = payloadField(row.payload, "groupName");
				lines.push(multiGroup && groupName ? `${groupName} · ${line}` : line);
			} else if (comments.length > 1 && comments[0]) {
				const description = payloadField(comments[0].payload, "description");
				const groupName = payloadField(comments[0].payload, "groupName");
				const line = `${comments.length} bình luận mới về ${description}`;
				lines.push(multiGroup && groupName ? `${groupName} · ${line}` : line);
			}
		}
	}
	return lines;
}

export async function runSendDigest(deps: WorkerDeps): Promise<number> {
	const now = deps.now();
	const since = await getJobCheckpoint(deps.db, JOB_NAMES.sendDigest);
	const rows = await listUnreadDigestNotifications(deps.db, {
		since,
		until: now,
	});
	const byUser = new Map<string, DigestRow[]>();
	for (const row of rows) {
		const list = byUser.get(row.userId);
		if (list) list.push(row);
		else byUser.set(row.userId, [row]);
	}
	const mailer = deps.mailer ?? createConsoleMailer();
	let sentCount = 0;
	for (const [userId, userRows] of byUser) {
		const first = userRows[0];
		if (!first) continue;
		const allLines = buildUserDigestLines(userRows);
		if (allLines.length === 0) continue;
		const lines = allLines.slice(0, DIGEST_LINE_LIMIT);
		const overflowCount = Math.max(0, allLines.length - DIGEST_LINE_LIMIT);
		const unsubscribeToken = await issueUnsubscribeToken(
			deps.db,
			userId,
			first.unsubscribeTokenHash ?? null,
		);
		const mail = digestMail({
			webOrigin: deps.config.webOrigin,
			lines,
			overflowCount,
			unsubscribeToken,
		});
		await mailer.send({
			to: first.email,
			subject: mail.subject,
			text: mail.text,
			headers: mail.headers,
			template: "notification_digest",
			userId,
		});
		sentCount += 1;
	}
	await setJobCheckpoint(deps.db, {
		name: JOB_NAMES.sendDigest,
		lastRunAt: now,
	});
	return sentCount;
}

export async function registerSendDigestJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.sendDigest,
		SendDigestPayload,
		async (_data, workerDeps) => {
			await runSendDigest(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.sendDigest,
		"0 20 * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
