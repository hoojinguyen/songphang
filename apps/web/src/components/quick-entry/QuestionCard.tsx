"use client";
import {
	type CategoryDto,
	CreateTransactionRequest,
	type MemberDto,
	type ParseDraft,
	ParseResponse,
} from "@songphang/contract";
import { readSentence, toVietnamDate } from "@songphang/core";
import { useState } from "react";
import { usePreviewShares } from "../../lib/transactions";
import { t, vi } from "../../messages/vi";
import { ChoicePanel } from "./ChoicePanel";
import { ConfirmationCard } from "./ConfirmationCard";
import { DescriptionPrompt } from "./DescriptionPrompt";
export function QuestionCard({
	writerMemberId,
	result,
	members,
	categories,
	groupId,
	onSave,
	onEdit,
	onChangeCategory,
	disabled,
}: {
	writerMemberId: string | null;
	result: ParseResponse;
	members: MemberDto[];
	categories?: CategoryDto[] | undefined;
	groupId: string;
	onSave: (r: ParseResponse) => void;
	onEdit: (r: ParseResponse) => void;
	onChangeCategory?:
		| ((category: ParseDraft["category"], categoryId: string | null) => void)
		| undefined;
	disabled: boolean;
}) {
	const [selected, setSelected] = useState<string[]>([]);
	const [description, setDescription] = useState(
		result.draft.description ?? "",
	);
	const [names, setNames] = useState<Record<number, string>>({});

	const local = Object.keys(names).length
		? readSentence({
				text: result.text,
				members,
				writerMemberId,
				memberChoices: names,
			})
		: null;
	const resolved = ParseResponse.parse(
		local
			? {
					...result,
					status: local.status,
					issues: local.issues,
					draft: {
						type: "expense",
						description: local.draft.description,
						amount: local.draft.amount,
						split: local.draft.split,
						payers:
							local.draft.payerMemberId && local.draft.amount !== null
								? [
										{
											memberId: local.draft.payerMemberId,
											amount: local.draft.amount,
										},
									]
								: [],
						category: result.draft.category,
						categoryId: result.draft.categoryId,
					},
				}
			: result,
	);
	const issue = resolved.issues.find((i) => i.code === "MEMBER_AMBIGUOUS");
	const count = resolved.issues.find((i) => i.code === "COUNT_MISMATCH");
	const missing = resolved.issues.some((i) => i.code === "DESCRIPTION_MISSING");
	const chooseName = (id: string) => {
		if (issue?.candidates.includes(id))
			setNames((current) => ({ ...current, [issue.start]: id }));
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
		resolved.status !== "unparsed" &&
		!issue &&
		(!count || selected.length === count.count) &&
		(!missing || !!description.trim());
	const parsed = CreateTransactionRequest.safeParse({
		...draft,
		occurredAt: `${toVietnamDate(new Date())}T05:00:00.000Z`,
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
		!!preview.data;
	const effective: ParseResponse = {
		...resolved,
		draft,
		status: ready ? "ok" : "needs_input",
		issues: ready ? [] : resolved.issues,
		shares: complete && preview.current ? preview.data?.shares : undefined,
	};
	const word = issue ? result.text.slice(issue.start, issue.end) : "";
	return (
		<ConfirmationCard
			result={effective}
			members={members}
			groupId={groupId}
			categories={categories}
			onChangeCategory={onChangeCategory}
			onSave={() => onSave(effective)}
			onEdit={() => onEdit(effective)}
			disabled={disabled || !ready}
			overBudget={Boolean(
				ready && preview.data?.warnings.includes("BUDGET_OVER"),
			)}
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
			{preview.isError && <p role="alert">{vi.common.loadError}</p>}
		</ConfirmationCard>
	);
}
