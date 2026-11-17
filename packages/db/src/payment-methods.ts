import { and, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { members } from "./schema-groups.js";
import { memberPaymentMethods } from "./schema-payments.js";
export async function listPaymentMethodsByGroup(
	executor: DbExecutor,
	groupId: string,
) {
	const rows = await executor
		.select({
			memberId: members.id,
			kind: memberPaymentMethods.kind,
			bankBin: memberPaymentMethods.bankBin,
			accountNumber: memberPaymentMethods.accountNumber,
			accountName: memberPaymentMethods.accountName,
		})
		.from(memberPaymentMethods)
		.innerJoin(members, eq(members.id, memberPaymentMethods.memberId))
		.where(eq(members.groupId, groupId));
	const grouped = new Map<string, typeof rows>();
	for (const row of rows)
		grouped.set(row.memberId, [...(grouped.get(row.memberId) ?? []), row]);
	return grouped;
}
export async function replacePaymentMethods(
	executor: DbExecutor,
	input: {
		groupId: string;
		memberId: string;
		rows: (typeof memberPaymentMethods.$inferInsert)[];
	},
) {
	await executor.delete(memberPaymentMethods).where(
		and(
			eq(memberPaymentMethods.memberId, input.memberId),
			eq(
				memberPaymentMethods.memberId,
				executor
					.select({ id: members.id })
					.from(members)
					.where(
						and(
							eq(members.groupId, input.groupId),
							eq(members.id, input.memberId),
						),
					),
			),
		),
	);
	if (input.rows.length > 0)
		await executor.insert(memberPaymentMethods).values(input.rows);
}
