"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
	type ParseDraft,
	type ParsedDraftResult,
	type ParseResponse,
} from "@songphang/contract";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { ConfirmationCard } from "../../../../../components/quick-entry/ConfirmationCard";
import { QuestionCard } from "../../../../../components/quick-entry/QuestionCard";
import { SentenceInput } from "../../../../../components/quick-entry/SentenceInput";
import { Icon } from "../../../../../components/ui/Icon";
import { OnlineButton } from "../../../../../components/ui/OnlineButton";
import { ScreenHeader } from "../../../../../components/ui/ScreenHeader";
import { useCategories } from "../../../../../lib/categories";
import { useDraft } from "../../../../../lib/draft-context";
import { useParseSentence } from "../../../../../lib/quick-entry";
import {
	useCreateTransaction,
	usePreviewShares,
} from "../../../../../lib/transactions";
import { t, vi } from "../../../../../messages/vi";

const INTERACTIVE_ISSUES = new Set([
	"MEMBER_AMBIGUOUS",
	"COUNT_MISMATCH",
	"DESCRIPTION_MISSING",
]);

function isRuleInteractiveQuestion(
	item: ParsedDraftResult,
	reader: ParseResponse["reader"],
) {
	return (
		reader !== "ai" &&
		item.status === "needs_input" &&
		item.issues.some((issue) => INTERACTIVE_ISSUES.has(issue.code))
	);
}
export function ComposeScreen({
	writerMemberId,
	groupId,
	groupName,
	members,
}: {
	writerMemberId: string | null;
	groupId: string;
	groupName: string;
	members: MemberDto[];
}) {
	const memory = useDraft();
	const { sentence, setSentence } = memory;
	const query = useParseSentence(groupId, sentence);
	const categoriesQuery = useCategories(groupId);
	const categories = categoriesQuery.data ?? [];
	const mutation = useCreateTransaction(groupId);
	const router = useRouter();
	const keys = useRef(new Map<string, { key: string; occurredAt: string }>());
	const saving = useRef(false);
	const [collapsing, setCollapsing] = useState(false);
	const [slowPending, setSlowPending] = useState(false);
	const [previewAt] = useState(
		() =>
			`${new Date(Date.now() + 7 * 3600_000).toISOString().slice(0, 10)}T05:00:00.000Z`,
	);
	const result = sentence.trim() ? query.data : undefined;
	useEffect(() => {
		if (!query.isFetching || !sentence.trim()) {
			setSlowPending(false);
			return;
		}
		const timer = setTimeout(() => setSlowPending(true), 1000);
		return () => clearTimeout(timer);
	}, [query.isFetching, sentence]);

	const [queueState, setQueueState] = useState<{
		forResult: ParseResponse | undefined;
		index: number;
		overrides: Record<
			number,
			{ category: ParseDraft["category"]; categoryId: string | null }
		>;
	}>({ forResult: undefined, index: 0, overrides: {} });
	const activeIndex = queueState.forResult === result ? queueState.index : 0;
	const overrides = queueState.forResult === result ? queueState.overrides : {};
	const items: ParsedDraftResult[] = result
		? [
				{
					status: result.status,
					draft: result.draft,
					issues: result.issues,
					shares: result.shares,
				},
				...result.moreDrafts,
			]
		: [];
	const activeItem = items[activeIndex];
	const activeOverride = overrides[activeIndex];
	const activeDraft: ParseDraft | null = activeItem
		? activeOverride
			? { ...activeItem.draft, ...activeOverride }
			: activeItem.draft
		: null;

	const okPreview =
		query.current && activeItem?.status === "ok" && activeDraft
			? CreateTransactionRequest.safeParse({
					...activeDraft,
					occurredAt: previewAt,
				})
			: null;
	const preview = usePreviewShares(
		groupId,
		okPreview?.success ? okPreview.data : null,
	);
	useEffect(() => {
		if (
			query.current &&
			result &&
			activeItem &&
			activeDraft &&
			activeItem.status !== "ok" &&
			!isRuleInteractiveQuestion(activeItem, result.reader) &&
			memory.draft?.sentence !== sentence
		) {
			memory.setDraft({
				sentence,
				draft: activeDraft,
				issues: activeItem.issues,
				spans: result.reader === "ai" ? [] : result.spans,
			});
			router.replace(`/g/${groupId}/tx/new?form`);
		}
	}, [
		query.current,
		result,
		activeItem,
		activeDraft,
		memory,
		sentence,
		router,
		groupId,
	]);

	const setActiveCategory = (
		category: ParseDraft["category"],
		categoryId: string | null,
	) => {
		if (!result) return;
		setQueueState({
			forResult: result,
			index: activeIndex,
			overrides: {
				...overrides,
				[activeIndex]: { category, categoryId },
			},
		});
	};

	const activeCardResult: ParseResponse | undefined =
		result && activeItem && activeDraft
			? {
					...result,
					status: activeItem.status,
					draft: activeDraft,
					issues: activeItem.issues,
					shares: preview.data?.shares ?? activeItem.shares,
					spans: result.reader === "ai" ? [] : result.spans,
				}
			: undefined;

	const edit = (chosen?: ParseResponse) => {
		if (result?.text !== sentence || !activeItem || !activeDraft) return;
		memory.setDraft({
			sentence,
			draft: chosen?.draft ?? activeDraft,
			issues: activeItem.issues,
			spans: result.reader === "ai" ? [] : result.spans,
		});
		router.push(`/g/${groupId}/tx/new?form`);
	};
	const skip = () => {
		if (saving.current || mutation.isPending || !result) return;
		if (activeIndex < items.length - 1) {
			setQueueState({
				forResult: result,
				index: activeIndex + 1,
				overrides,
			});
			return;
		}
		memory.clear();
		router.replace(`/g/${groupId}`);
	};
	const save = (chosen?: ParseResponse) => {
		const savingResult = chosen ?? activeCardResult;
		if (
			savingResult?.status !== "ok" ||
			!query.current ||
			saving.current ||
			!result
		)
			return;
		const keySlot = `${sentence}:${activeIndex}`;
		let identity = keys.current.get(keySlot);
		if (!identity) {
			identity = {
				key: crypto.randomUUID(),
				occurredAt: new Date().toISOString(),
			};
			keys.current.set(keySlot, identity);
		}
		const parsed = CreateTransactionRequest.safeParse({
			...savingResult.draft,
			occurredAt: identity.occurredAt,
		});
		if (!parsed.success) return;
		saving.current = true;
		mutation.mutate(
			{ request: parsed.data, key: identity.key },
			{
				onSuccess: () => {
					if (activeIndex < items.length - 1) {
						saving.current = false;
						setQueueState({
							forResult: result,
							index: activeIndex + 1,
							overrides,
						});
						return;
					}
					setCollapsing(true);
					const reduced = window.matchMedia(
						"(prefers-reduced-motion: reduce)",
					).matches;
					setTimeout(
						() => {
							memory.clear();
							router.replace(`/g/${groupId}`);
						},
						reduced ? 0 : 250,
					);
				},
				onError: () => {
					saving.current = false;
				},
			},
		);
	};
	const isMultiDraft = items.length > 1;
	const indexLabel = isMultiDraft
		? t(vi.compose.draftIndex, {
				index: String(activeIndex + 1),
				count: String(items.length),
			})
		: undefined;
	const saveLabel =
		isMultiDraft && activeIndex < items.length - 1
			? vi.compose.saveAndNext
			: vi.compose.save;
	return (
		<div className="flex flex-1 flex-col gap-5">
			<ScreenHeader
				title={vi.compose.title}
				subtitle={groupName}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.cancel}
				backIcon="close"
			/>
			<div
				className={`compose-card my-auto ${collapsing ? "compose-collapsing" : ""}`}
			>
				{activeCardResult &&
				activeItem &&
				result &&
				isRuleInteractiveQuestion(activeItem, result.reader) ? (
					<QuestionCard
						writerMemberId={writerMemberId}
						key={`${result.text}:${activeIndex}`}
						result={activeCardResult}
						members={members}
						categories={categories}
						groupId={groupId}
						onChangeCategory={setActiveCategory}
						onEdit={edit}
						onSave={save}
						disabled={!query.current || mutation.isPending}
					/>
				) : activeCardResult?.status === "ok" && result ? (
					<ConfirmationCard
						key={`${result.text}:${activeIndex}`}
						result={activeCardResult}
						members={members}
						groupId={groupId}
						categories={categories}
						onChangeCategory={setActiveCategory}
						onEdit={() => edit()}
						onSave={() => save()}
						onSkip={isMultiDraft ? skip : undefined}
						saveLabel={saveLabel}
						skipLabel={isMultiDraft ? vi.compose.skipDraft : undefined}
						indexLabel={indexLabel}
						disabled={!query.current || mutation.isPending}
						overBudget={Boolean(
							preview.current && preview.data?.warnings.includes("BUDGET_OVER"),
						)}
					/>
				) : null}
			</div>
			{slowPending && (
				<p role="status" className="text-center text-sm font-bold text-muted">
					{vi.compose.reading}
				</p>
			)}
			{query.isError && <p role="alert">{vi.common.loadError}</p>}
			{mutation.isError && <p role="alert">{vi.common.saveError}</p>}
			<Link
				href={`/g/${groupId}/tx/new?form`}
				onClick={() => {
					if (result?.text === sentence && activeItem && activeDraft)
						memory.setDraft({
							sentence,
							draft: activeDraft,
							issues: activeItem.issues,
							spans: result.reader === "ai" ? [] : result.spans,
						});
					else memory.setDraft(null);
				}}
				className="min-h-11 text-center font-bold"
			>
				{vi.feed.manualEntry}
			</Link>
			<div className="mt-auto flex items-end gap-3 rounded-[30px] border-[3px] border-ink bg-surface p-3">
				<SentenceInput
					text={sentence}
					spans={
						result?.text === sentence && result.reader !== "ai"
							? result.spans
							: []
					}
					onChange={setSentence}
					onSend={query.send}
				/>
				<OnlineButton
					type="button"
					aria-label={vi.compose.send}
					onClick={query.send}
					disabled={!sentence.trim()}
					className="flex size-[52px] shrink-0 items-center justify-center rounded-[20px] bg-ink text-surface"
				>
					<Icon name="send" size={24} />
				</OnlineButton>
			</div>
		</div>
	);
}
