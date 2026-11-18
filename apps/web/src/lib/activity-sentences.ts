import {
	type ActivityDto,
	type MemberDto,
	SplitInput,
} from "@songphang/contract";
import { z } from "zod";
import { vi } from "../messages/vi";
import { formatAmount, formatMoney } from "./money";
export type ChangeChip = { field: string; before: string; after: string };
export type TextPart = { text: string; bold: boolean; key: string };
function string(value: unknown) {
	const p = z.string().safeParse(value);
	return p.success ? p.data : vi.common.pendingValue;
}
function amount(value: unknown, currency = false) {
	const p = z.number().int().safeParse(value);
	return p.success
		? currency
			? formatMoney(p.data)
			: formatAmount(p.data)
		: vi.common.pendingValue;
}
function parts(template: string, values: Record<string, string>): TextPart[] {
	let offset = 0;
	return template
		.split(/(\{[a-zA-Z]+\})/)
		.filter(Boolean)
		.map((part) => {
			const key = String(offset);
			offset += part.length;
			return part.startsWith("{")
				? { key, text: values[part.slice(1, -1)] ?? "", bold: true }
				: { key, text: part, bold: false };
		});
}

function fieldValue(key: string, value: unknown, members: MemberDto[]): string {
	const name = (id: string) =>
		members.find((m) => m.id === id)?.name ?? vi.activity.someone;
	if (key === "amount") return amount(value);
	if (key === "occurredAt") {
		const p = z.iso.datetime().safeParse(value);
		return p.success
			? new Date(p.data).toLocaleString("vi-VN")
			: vi.common.pendingValue;
	}
	if (key === "payers" || key === "shares") {
		const p = z
			.array(z.object({ memberId: z.string(), amount: z.number().int() }))
			.safeParse(value);
		return p.success
			? p.data
					.map((e) => `${name(e.memberId)} ${formatAmount(e.amount)}`)
					.join(" · ")
			: vi.common.pendingValue;
	}
	if (key === "split") {
		const p = SplitInput.safeParse(value);
		if (!p.success) return vi.common.pendingValue;
		const split = p.data;
		if (split.method === "equal") {
			return split.members.map(name).join(" · ");
		}
		if (split.method === "items") {
			return split.items
				.map((item) => `${item.name} ${formatAmount(item.amount)}`)
				.join(" · ");
		}
		return split.entries
			.map(
				(e) =>
					`${name(e.memberId)} ${"amount" in e ? formatAmount(e.amount) : "weight" in e ? e.weight : e.percent}`,
			)
			.join(" · ");
	}
	if (key === "category") {
		const labels = vi.expenseForm.categories;
		return value === null
			? vi.common.pendingValue
			: typeof value === "string" && Object.hasOwn(labels, value)
				? string(Reflect.get(labels, value))
				: vi.common.pendingValue;
	}
	return typeof value === "boolean"
		? value
			? vi.members.reactivate
			: vi.members.deactivate
		: string(value);
}
function changedFields(entry: ActivityDto, members: MemberDto[]): ChangeChip[] {
	if (entry.action !== "update") return [];
	const before = entry.before ?? {};
	const after = entry.after ?? {};
	const labels: Record<string, string> = {
		amount: vi.activity.amount,
		description: vi.activity.description,
		occurredAt: vi.activity.date,
		category: vi.activity.category,
		payers: vi.activity.payers,
		shares: vi.activity.split,
		split: vi.activity.split,
		name: vi.activity.description,
		defaultWeight: vi.split.modeShares,
	};
	return Object.keys(after)
		.filter(
			(k) =>
				Object.hasOwn(before, k) &&
				Object.hasOwn(labels, k) &&
				JSON.stringify(before[k]) !== JSON.stringify(after[k]) &&
				!(k === "split" && Object.hasOwn(after, "shares")),
		)
		.map((k) => ({
			field: labels[k] ?? "",
			before: fieldValue(k, before[k], members),
			after: fieldValue(k, after[k], members),
		}));
}
export function describeActivity(
	entry: ActivityDto,
	members: MemberDto[],
): { parts: TextPart[]; chips: ChangeChip[] } {
	const after = entry.after ?? {};
	const before = entry.before ?? {};
	const name = (id: unknown) =>
		typeof id === "string"
			? (members.find((m) => m.id === id)?.name ?? vi.activity.someone)
			: vi.activity.someone;
	const actor = entry.actor?.name ?? vi.activity.someone;
	const values: Record<string, string> = {
		actor,
		summary: entry.summary,
		amount: amount(after.amount ?? before.amount, true),
		count: string(
			typeof after.memberCount === "number"
				? String(after.memberCount)
				: undefined,
		),
		member: typeof after.name === "string" ? after.name : entry.summary,
		name: string(after.name),
		role:
			after.role === "viewer" ? vi.members.roleViewer : vi.members.roleEditor,
		from: vi.activity.someone,
		to: vi.activity.someone,
	};
	const payers = z
		.array(z.object({ memberId: z.string() }))
		.safeParse(after.payers);
	const shares = z
		.array(z.object({ memberId: z.string() }))
		.safeParse(after.shares);
	if (payers.success) values.from = name(payers.data[0]?.memberId);
	if (shares.success) values.to = name(shares.data[0]?.memberId);
	let templates: string[] = [];
	if (entry.entityType === "transaction")
		templates = [
			entry.action === "create"
				? after.type === "transfer"
					? vi.activity.transfer
					: after.type === "income"
						? vi.activity.income
						: vi.activity.expense
				: entry.action === "update"
					? vi.activity.edit
					: entry.action === "delete"
						? vi.activity.delete
						: entry.action === "dispute_open"
							? vi.activity.disputeOpen
							: entry.action === "dispute_resolve"
								? vi.activity.disputeResolve
								: vi.activity.restore,
		];
	else if (entry.entityType === "group") {
		if (entry.action === "create") templates = [vi.activity.groupCreate];
		else {
			if (Object.hasOwn(after, "name")) templates.push(vi.activity.groupName);
			if (typeof after.minimizeDebts === "boolean")
				templates.push(
					after.minimizeDebts
						? vi.activity.minimizeOn
						: vi.activity.minimizeOff,
				);
			if (Object.hasOwn(after, "defaultRole")) {
				values.role =
					after.defaultRole === "viewer"
						? vi.members.roleViewer
						: vi.members.roleEditor;
				templates.push(vi.activity.defaultRole);
			}
			if (typeof after.inviteActive === "boolean")
				templates.push(
					after.inviteActive ? vi.activity.inviteOn : vi.activity.inviteOff,
				);
			if (after.inviteRotated === true)
				templates.push(vi.activity.inviteRotate);
		}
	} else if (entry.entityType === "member")
		templates = [
			entry.action === "create"
				? vi.activity.memberAdd
				: entry.action === "delete"
					? vi.activity.memberDelete
					: typeof after.active === "boolean"
						? after.active
							? vi.activity.memberActive
							: vi.activity.memberInactive
						: Object.hasOwn(after, "name")
							? vi.activity.memberName
							: vi.activity.memberWeight,
		];
	else
		templates = [
			entry.action === "join"
				? vi.activity.join
				: entry.action === "leave"
					? vi.activity.leave
					: entry.action === "remove"
						? vi.activity.remove
						: entry.action === "role_change"
							? vi.activity.role
							: entry.action === "transfer_ownership"
								? vi.activity.ownership
								: vi.activity.choose,
		];
	return {
		parts: parts(templates.join(" · "), values),
		chips: changedFields(entry, members),
	};
}
