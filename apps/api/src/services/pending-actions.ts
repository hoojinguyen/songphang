import { GroupRole } from "@songphang/contract";
import type {
	listMembersForGroups,
	listPendingApprovalsForGroups,
	listPendingSettlementsForGroups,
} from "@songphang/db";
import { mayResolve } from "./settlement-requests.js";

type GroupContext = {
	id: string;
	name: string;
	archivedAt: Date | null;
	role: string;
	memberId: string | null;
};

type MemberRow = Awaited<ReturnType<typeof listMembersForGroups>>[number];
type PendingSettlementRow = Awaited<
	ReturnType<typeof listPendingSettlementsForGroups>
>[number];
type PendingApprovalRow = Awaited<
	ReturnType<typeof listPendingApprovalsForGroups>
>[number];

export type ActionablePendingItem =
	| {
			kind: "settlement_confirmation";
			id: string;
			groupId: string;
			groupName: string;
			amount: number;
			actorName: string;
			description: string;
			createdAt: Date;
	  }
	| {
			kind: "expense_approval";
			id: string;
			groupId: string;
			groupName: string;
			amount: number;
			actorName: string;
			description: string;
			createdAt: Date;
	  };

export function collectPendingActions(input: {
	groups: GroupContext[];
	members: MemberRow[];
	pendingSettlements: PendingSettlementRow[];
	pendingApprovals: PendingApprovalRow[];
}) {
	const groupById = new Map(input.groups.map((group) => [group.id, group]));
	const memberById = new Map(
		input.members.map((member) => [member.id, member]),
	);
	const countByGroupId = new Map<string, number>();
	let pendingSettlementCount = 0;
	let pendingApprovalCount = 0;
	const items: ActionablePendingItem[] = [];

	for (const row of input.pendingSettlements) {
		const group = groupById.get(row.groupId);
		if (!group || group.archivedAt !== null) continue;
		const receiver = memberById.get(row.toMemberId);
		if (!receiver) continue;
		const role = GroupRole.parse(group.role);
		if (!mayResolve({ role, memberId: group.memberId }, receiver)) continue;
		const fromName = memberById.get(row.fromMemberId)?.name ?? "";
		pendingSettlementCount += 1;
		countByGroupId.set(group.id, (countByGroupId.get(group.id) ?? 0) + 1);
		items.push({
			kind: "settlement_confirmation",
			id: row.id,
			groupId: group.id,
			groupName: group.name,
			amount: row.amount,
			actorName: fromName,
			description: `${fromName} → ${receiver.name}`,
			createdAt: row.createdAt,
		});
	}

	for (const row of input.pendingApprovals) {
		const group = groupById.get(row.groupId);
		if (!group || group.archivedAt !== null) continue;
		if (GroupRole.parse(group.role) !== "owner") continue;
		pendingApprovalCount += 1;
		countByGroupId.set(group.id, (countByGroupId.get(group.id) ?? 0) + 1);
		items.push({
			kind: "expense_approval",
			id: row.id,
			groupId: group.id,
			groupName: group.name,
			amount: row.amount,
			actorName: row.creatorName ?? "",
			description: row.description,
			createdAt: row.createdAt,
		});
	}

	items.sort((a, b) => {
		const timeDiff = b.createdAt.getTime() - a.createdAt.getTime();
		if (timeDiff !== 0) return timeDiff;
		return b.id.localeCompare(a.id);
	});

	return {
		countByGroupId,
		pendingSettlementCount,
		pendingApprovalCount,
		items,
	};
}
