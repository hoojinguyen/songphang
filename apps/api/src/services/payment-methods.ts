import {
	MemberResponse,
	PaymentMethodDto,
	type PaymentMethodInput,
} from "@songphang/contract";
import { findBank } from "@songphang/core";
import {
	findMember,
	insertActivity,
	listPaymentMethodsByGroup,
	lockGroup,
	replacePaymentMethods,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";

export function paymentMethodDto(row: {
	kind: string;
	bankBin: string | null;
	accountNumber: string;
	accountName: string | null;
}) {
	return PaymentMethodDto.parse(
		row.kind === "bank"
			? {
					kind: row.kind,
					bankBin: row.bankBin,
					accountNumber: row.accountNumber,
					accountName: row.accountName,
					bankShortName: findBank(row.bankBin ?? "")?.shortName,
				}
			: { kind: row.kind, phone: row.accountNumber },
	);
}
export async function setPaymentMethods(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		memberId: string;
		methods: PaymentMethodInput[];
	},
) {
	const response = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			...input,
			minimumRole: "viewer",
		});
		const member = await findMember(executor, input.groupId, input.memberId);
		if (member === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (access.role === "viewer" && access.memberId !== member.id)
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		const now = deps.now();
		await replacePaymentMethods(executor, {
			...input,
			rows: input.methods.map((method) => ({
				memberId: member.id,
				kind: method.kind,
				bankBin: method.kind === "bank" ? method.bankBin : null,
				accountNumber:
					method.kind === "bank" ? method.accountNumber : method.phone,
				accountName: method.kind === "bank" ? method.accountName : null,
				createdAt: now,
				updatedAt: now,
			})),
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "member",
			entityId: member.id,
			summary: member.name,
			createdAt: now,
		});
		return MemberResponse.parse({
			member: {
				...member,
				isMe: member.id === access.memberId,
				paymentMethods:
					(await listPaymentMethodsByGroup(executor, input.groupId))
						.get(member.id)
						?.map(paymentMethodDto) ?? [],
			},
		});
	});
	deps.events.publishChanged(input.groupId, ["members", "balances"]);
	return response;
}
