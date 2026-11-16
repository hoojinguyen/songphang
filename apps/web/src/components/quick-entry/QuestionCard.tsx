"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
	ParseResponse,
} from "@songphang/contract";
import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { type ApiError, apiFetch } from "../../lib/api";
import { jsonRequest } from "../../lib/request";
import { usePreviewShares } from "../../lib/transactions";
import { t, vi } from "../../messages/vi";
import { ChoicePanel } from "./ChoicePanel";
import { ConfirmationCard } from "./ConfirmationCard";
import { DescriptionPrompt } from "./DescriptionPrompt";
export function QuestionCard({
	result,
	members,
	groupId,
	onSave,
	onEdit,
	disabled,
}: {
	result: ParseResponse;
	members: MemberDto[];
	groupId: string;
	onSave: (r: ParseResponse) => void;
	onEdit: (r: ParseResponse) => void;
	disabled: boolean;
}) {
	const [resolved, setResolved] = useState(result);
	const [selected, setSelected] = useState<string[]>([]);
	const [description, setDescription] = useState(
		result.draft.description ?? "",
	);
	const [names, setNames] = useState<Record<number, string>>({});
	const issue = resolved.issues.find((i) => i.code === "MEMBER_AMBIGUOUS");
	const count = resolved.issues.find((i) => i.code === "COUNT_MISMATCH");
	const missing = resolved.issues.some((i) => i.code === "DESCRIPTION_MISSING");
	const reparse = useMutation<
		ParseResponse,
		ApiError,
		{ text: string; names: Record<number, string> }
	>({
		mutationFn: (input) =>
			apiFetch(
				`/groups/${groupId}/transactions/parse`,
				ParseResponse,
				jsonRequest("POST", { text: input.text }),
			),
		onSuccess: (next, input) => {
			setNames(input.names);
			setResolved({
				...next,
				text: result.text,
				spans: result.spans,
				issues: next.issues.map((i) => {
					const original = result.issues.find(
						(o) =>
							o.code === i.code &&
							names[o.start] === undefined &&
							input.names[o.start] === undefined,
					);
					return original ?? i;
				}),
			});
		},
	});
	const chooseName = (id: string) => {
		if (!issue) return;
		const name = members.find((m) => m.id === id)?.name;
		if (!name) return;
		const next = { ...names, [issue.start]: name };
		let text = result.text;
		for (const original of result.issues
			.filter((i) => i.code === "MEMBER_AMBIGUOUS")
			.toSorted((a, b) => b.start - a.start)) {
			const chosen = next[original.start];
			if (chosen)
				text =
					original.start === original.end
						? `${text} ${chosen} trả`
						: text.slice(0, original.start) + chosen + text.slice(original.end);
		}
		reparse.mutate({ text, names: next });
	};
	const draft = {
		...resolved.draft,
		description: missing
			? description.trim() || null
			: resolved.draft.description,
		split: count
			? selected.length === count.count
				? {
						method: "equal" as const,
						members: members
							.filter((m) => selected.includes(m.id))
							.map((m) => m.id),
					}
				: null
			: resolved.draft.split,
	};
	const complete =
		!issue &&
		(!count || selected.length === count.count) &&
		(!missing || !!description.trim());
	const parsed = CreateTransactionRequest.safeParse({
		...draft,
		occurredAt: "2026-01-01T00:00:00.000Z",
		category: null,
	});
	const preview = usePreviewShares(
		groupId,
		complete && parsed.success ? parsed.data : null,
	);
	const ready =
		complete &&
		parsed.success &&
		preview.current &&
		!preview.isFetching &&
		!preview.isPlaceholderData &&
		!!preview.data &&
		!reparse.isPending;
	const effective: ParseResponse = {
		...resolved,
		draft,
		status: ready ? "ok" : "needs_input",
		issues: ready ? [] : resolved.issues,
		shares: complete ? preview.data?.shares : undefined,
	};
	const word = issue ? result.text.slice(issue.start, issue.end) : "";
	return (
		<ConfirmationCard
			result={effective}
			members={members}
			onSave={() => onSave(effective)}
			onEdit={() => onEdit(effective)}
			disabled={disabled || !ready}
			saveLabel={
				count && selected.length < (count.count ?? 0)
					? t(vi.compose.chooseMore, {
							count: String((count.count ?? 0) - selected.length),
						})
					: vi.compose.save
			}
		>
			{issue ? (
				<ChoicePanel
					members={members.filter((m) => issue.candidates.includes(m.id))}
					selected={[]}
					count={1}
					title={
						word ? t(vi.compose.whichMember, { word }) : vi.compose.whoPaid
					}
					reason={
						word
							? t(vi.compose.memberReason, { word })
							: vi.compose.nothingSaved
					}
					onChoose={chooseName}
				/>
			) : count ? (
				<ChoicePanel
					members={members.filter((m) => count.candidates.includes(m.id))}
					selected={selected}
					count={count.count ?? 0}
					title={t(vi.compose.whichPeople, { count: String(count.count) })}
					reason={t(vi.compose.countReason, {
						total: String(members.filter((m) => m.active).length),
					})}
					onChoose={(id) =>
						setSelected((current) =>
							current.includes(id)
								? current.filter((x) => x !== id)
								: current.length < (count.count ?? 0)
									? [...current, id]
									: current,
						)
					}
				/>
			) : null}
			{missing && !issue && (
				<DescriptionPrompt value={description} onChange={setDescription} />
			)}
			{(preview.isError || reparse.isError) && (
				<p role="alert">{vi.common.loadError}</p>
			)}
		</ConfirmationCard>
	);
}
