"use client";
import {
	type CreateRecurringExpenseRequest,
	type RecurringExpenseDto,
	RecurringExpenseResponse,
	RecurringExpensesResponse,
	type UpdateRecurringExpenseRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { t, vi } from "../messages/vi";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

export function useRecurringExpenses(groupId: string, enabled = true) {
	return useQuery<RecurringExpenseDto[], ApiError>({
		queryKey: ["group", groupId, "recurringExpenses"],
		enabled,
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/recurring-expenses`,
					RecurringExpensesResponse,
				)
			).recurringExpenses,
	});
}

function useInvalidateRecurring(groupId: string) {
	const client = useQueryClient();
	return async () => {
		await Promise.all([
			client.invalidateQueries({
				queryKey: ["group", groupId, "recurringExpenses"],
			}),
			client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
			client.invalidateQueries({ queryKey: ["me", "overview"] }),
		]);
	};
}

export function useCreateRecurringExpense(groupId: string) {
	const invalidate = useInvalidateRecurring(groupId);
	return useMutation<
		RecurringExpenseDto,
		ApiError,
		{ request: CreateRecurringExpenseRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/recurring-expenses`,
					RecurringExpenseResponse,
					jsonRequest("POST", request, key),
				)
			).recurringExpense,
		onSuccess: invalidate,
	});
}

export function useUpdateRecurringExpense(groupId: string) {
	const invalidate = useInvalidateRecurring(groupId);
	return useMutation<
		RecurringExpenseDto,
		ApiError,
		{ recurringId: string; request: UpdateRecurringExpenseRequest }
	>({
		mutationFn: async ({ recurringId, request }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/recurring-expenses/${encodeURIComponent(recurringId)}`,
					RecurringExpenseResponse,
					jsonRequest("PATCH", request),
				)
			).recurringExpense,
		onSuccess: invalidate,
	});
}

export function useDeleteRecurringExpense(groupId: string) {
	const invalidate = useInvalidateRecurring(groupId);
	return useMutation<void, ApiError, string>({
		mutationFn: (recurringId) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/recurring-expenses/${encodeURIComponent(recurringId)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: invalidate,
	});
}

export function useSkipRecurringExpense(groupId: string) {
	const invalidate = useInvalidateRecurring(groupId);
	return useMutation<RecurringExpenseDto, ApiError, string>({
		mutationFn: async (recurringId) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/recurring-expenses/${encodeURIComponent(recurringId)}/skip`,
					RecurringExpenseResponse,
					jsonRequest("POST"),
				)
			).recurringExpense,
		onSuccess: invalidate,
	});
}

export function formatCalendarDateVN(calendarDate: string): string {
	const [year, month, day] = calendarDate.split("-");
	if (!year || !month || !day) return calendarDate;
	return `${day}/${month}/${year}`;
}

export function recurringFrequencyLabel(
	frequency: RecurringExpenseDto["frequency"],
): string {
	switch (frequency) {
		case "weekly":
			return vi.recurring.freqWeekly;
		case "monthly":
			return vi.recurring.freqMonthly;
		case "quarterly":
			return vi.recurring.freqQuarterly;
		case "yearly":
			return vi.recurring.freqYearly;
	}
}

export function formatRecurringScheduleSummary(
	item: RecurringExpenseDto,
): string {
	const freq = recurringFrequencyLabel(item.frequency);
	const nextDate = t(vi.recurring.nextDueTemplate, {
		date: formatCalendarDateVN(item.nextDueDate),
	});
	return `${freq} · ${nextDate}`;
}
