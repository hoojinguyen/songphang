import { z } from "@hono/zod-openapi";

export const HouseholdName = z.string().trim().min(1).max(50);

export const HouseholdDto = z
	.object({
		id: z.uuid(),
		name: HouseholdName,
		representativeMemberId: z.uuid(),
		memberIds: z.array(z.uuid()).min(2).max(20),
		createdAt: z.iso.datetime(),
		updatedAt: z.iso.datetime(),
	})
	.openapi("HouseholdDto");
export type HouseholdDto = z.infer<typeof HouseholdDto>;

export const HouseholdsResponse = z
	.object({ households: z.array(HouseholdDto) })
	.openapi("HouseholdsResponse");
export type HouseholdsResponse = z.infer<typeof HouseholdsResponse>;

export const HouseholdResponse = z
	.object({ household: HouseholdDto })
	.openapi("HouseholdResponse");
export type HouseholdResponse = z.infer<typeof HouseholdResponse>;

const HouseholdMemberIds = z
	.array(z.uuid())
	.min(2)
	.max(20)
	.refine((ids) => new Set(ids).size === ids.length);

export const CreateHouseholdRequest = z
	.object({
		name: HouseholdName,
		memberIds: HouseholdMemberIds,
		representativeMemberId: z.uuid(),
	})
	.refine((request) =>
		request.memberIds.includes(request.representativeMemberId),
	)
	.openapi("CreateHouseholdRequest");
export type CreateHouseholdRequest = z.infer<typeof CreateHouseholdRequest>;

export const UpdateHouseholdRequest = z
	.object({
		name: HouseholdName.optional(),
		memberIds: HouseholdMemberIds.optional(),
		representativeMemberId: z.uuid().optional(),
	})
	.refine(
		(request) =>
			Object.keys(request).length > 0 &&
			(request.memberIds === undefined ||
				request.representativeMemberId === undefined ||
				request.memberIds.includes(request.representativeMemberId)),
	)
	.openapi("UpdateHouseholdRequest");
export type UpdateHouseholdRequest = z.infer<typeof UpdateHouseholdRequest>;

export const HouseholdTransferRefDto = z
	.object({
		id: z.uuid(),
		name: HouseholdName,
		memberIds: z.array(z.uuid()),
	})
	.openapi("HouseholdTransferRefDto");
export type HouseholdTransferRefDto = z.infer<typeof HouseholdTransferRefDto>;

export const HouseholdBalanceDto = z
	.object({
		id: z.uuid(),
		name: HouseholdName,
		representativeMemberId: z.uuid(),
		memberIds: z.array(z.uuid()),
		netBalance: z.int(),
		memberBalances: z.array(
			z.object({
				memberId: z.uuid(),
				balance: z.int(),
			}),
		),
	})
	.openapi("HouseholdBalanceDto");
export type HouseholdBalanceDto = z.infer<typeof HouseholdBalanceDto>;
