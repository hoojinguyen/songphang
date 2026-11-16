"use client";
import { type MemberDto, SplitInput } from "@songphang/contract";
import { useState } from "react";
import { formatMoney, parseAmountInput } from "../../lib/money";
import { t, vi } from "../../messages/vi";
export type SplitMethod = "equal" | "exact" | "shares" | "percent";
function hundredths(value: string): number | null {
	if (!/^\d{1,3}(\.\d{1,2})?$/.test(value)) return null;
	const [whole, fraction = ""] = value.split(".");
	return Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
}
function percentText(value: number): string {
	const digits = String(value).padStart(3, "0");
	return `${digits.slice(0, -2)}.${digits.slice(-2)}`.replace(/\.?0+$/, "");
}
export function useSplitState(
	members: MemberDto[],
	amount: number,
	initial?: SplitInput | null,
) {
	const [method, setMethod] = useState<SplitMethod>(initial?.method ?? "equal");
	const [ids, setIds] = useState(
		initial
			? initial.method === "equal" || initial.method === "exact"
				? initial.members
				: initial.entries.map((e) => e.memberId)
			: members.map((member) => member.id),
	);
	const [values, setValues] = useState<Record<string, string>>(() =>
		initial && initial.method !== "equal"
			? Object.fromEntries(
					initial.entries.map((e) => [
						e.memberId,
						"amount" in e
							? String(e.amount)
							: "weight" in e
								? e.weight
								: e.percent,
					]),
				)
			: {},
	);
	const [spread, setSpread] = useState(
		initial?.method === "exact" && initial.remainder === "equal_among_all",
	);
	const selected = members.filter((member) => ids.includes(member.id));
	const blank = selected.filter((member) => !values[member.id]);
	const total = selected.reduce(
		(sum, member) => sum + (parseAmountInput(values[member.id] ?? "") ?? 0),
		0,
	);
	const rest = amount - total;
	const sumPercent = selected.reduce(
		(sum, member) => sum + (hundredths(values[member.id] ?? "") ?? 0),
		0,
	);
	const matched =
		method === "equal" ||
		method === "shares" ||
		(method === "exact" &&
			rest >= 0 &&
			(blank.length > 0 || spread || rest === 0)) ||
		(method === "percent" && sumPercent === 10000);
	const candidate =
		method === "equal"
			? { method, members: ids }
			: method === "exact"
				? {
						method,
						members: ids,
						entries: selected
							.filter((member) => values[member.id])
							.map((member) => ({
								memberId: member.id,
								amount: parseAmountInput(values[member.id] ?? ""),
							})),
						remainder:
							blank.length > 0
								? "equal_among_blank"
								: spread
									? "equal_among_all"
									: "none",
					}
				: {
						method,
						entries: selected.map((member) => ({
							memberId: member.id,
							...(method === "shares"
								? { weight: values[member.id] ?? member.defaultWeight }
								: { percent: values[member.id] ?? "" }),
						})),
					};
	const parsed = SplitInput.safeParse(candidate);
	const positiveWeight =
		method !== "shares" ||
		selected.some((member) =>
			/[1-9]/.test(values[member.id] ?? member.defaultWeight),
		);
	const split =
		parsed.success && matched && positiveWeight ? parsed.data : null;
	const text =
		method === "percent"
			? sumPercent === 10000
				? vi.split.percentMatch
				: t(sumPercent < 10000 ? vi.split.percentShort : vi.split.percentOver, {
						percent: percentText(Math.abs(10000 - sumPercent)),
					})
			: method === "exact" && rest < 0
				? t(vi.split.over, { amount: formatMoney(-rest) })
				: method === "exact" && blank.length > 0
					? t(vi.split.blankShare, {
							amount: formatMoney(rest),
							count: String(blank.length),
						})
					: !split
						? t(vi.split.short, { amount: formatMoney(Math.max(0, rest)) })
						: t(vi.split.match, { amount: formatMoney(amount) });
	return {
		method,
		ids,
		selected,
		values,
		spread,
		rest,
		blankCount: blank.length,
		split,
		status: { text, matched: split !== null },
		setSpread,
		changeMode: (next: SplitMethod) => {
			setMethod(next);
			setSpread(false);
			setValues(
				next === "shares"
					? Object.fromEntries(
							selected.map((member) => [member.id, member.defaultWeight]),
						)
					: {},
			);
		},
		setValue: (id: string, value: string) => {
			setValues((current) => ({ ...current, [id]: value }));
		},
		toggle: (id: string) => {
			setIds((current) =>
				current.includes(id)
					? current.filter((memberId) => memberId !== id)
					: members
							.filter(
								(member) => current.includes(member.id) || member.id === id,
							)
							.map((member) => member.id),
			);
			setValues((current) => {
				const next = { ...current };
				delete next[id];
				return next;
			});
		},
	};
}
