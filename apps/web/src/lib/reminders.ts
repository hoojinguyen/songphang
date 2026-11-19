"use client";
import {
	type BalancesResponse,
	type GroupRole,
	type MemberDto,
	type SendReminderRequest,
	SendReminderResponse,
} from "@songphang/contract";
import { useMutation } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";

const VN_DATE_PARTS = new Intl.DateTimeFormat("en-GB", {
	timeZone: "Asia/Ho_Chi_Minh",
	year: "numeric",
	month: "2-digit",
	day: "2-digit",
	hour: "2-digit",
	minute: "2-digit",
	hour12: false,
});

function vnParts(date: Date) {
	const parts = Object.fromEntries(
		VN_DATE_PARTS.formatToParts(date).map((part) => [part.type, part.value]),
	);
	return {
		dateKey: `${parts.year}-${parts.month}-${parts.day}`,
		day: parts.day ?? "",
		month: parts.month ?? "",
		hour: parts.hour === "24" ? "00" : (parts.hour ?? "00"),
		minute: parts.minute ?? "00",
	};
}

export function formatReminderNextAt(
	nextAtIso: string,
	now: Date = new Date(),
): string {
	const target = new Date(nextAtIso);
	if (Number.isNaN(target.getTime())) return nextAtIso;
	const targetVn = vnParts(target);
	const nowVn = vnParts(now);
	const time = `${targetVn.hour}:${targetVn.minute}`;
	if (targetVn.dateKey === nowVn.dateKey) return time;
	return `${time} ngày ${targetVn.day}/${targetVn.month}`;
}

export function canRemindTransfer(input: {
	transfer: BalancesResponse["transfers"][number];
	from: MemberDto;
	to: MemberDto;
	myMemberId: string | null;
	role: GroupRole;
	verified: boolean;
}): boolean {
	if (!input.verified) return false;
	if (input.transfer.pendingRequest) return false;
	if (
		input.from.kind !== "person" ||
		!input.from.claimed ||
		input.to.kind !== "person"
	)
		return false;
	if (input.from.id === input.myMemberId) return false;
	return input.role !== "viewer" || input.myMemberId === input.to.id;
}

export function useSendReminder(groupId: string) {
	return useMutation<SendReminderResponse, ApiError, SendReminderRequest>({
		mutationFn: (request) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/reminders`,
				SendReminderResponse,
				jsonRequest("POST", request),
			),
	});
}
