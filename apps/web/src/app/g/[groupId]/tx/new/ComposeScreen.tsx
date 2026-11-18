"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
	type ParseDraft,
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
import {
	isRuleInteractiveQuestion,
	useDraft,
} from "../../../../../lib/draft-context";
import { useParseSentence } from "../../../../../lib/quick-entry";
import {
	useCreateTransaction,
	usePreviewShares,
} from "../../../../../lib/transactions";
import { t, vi } from "../../../../../messages/vi";
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

	useEffect(() => {
		if (!query.current || !result || result.text !== sentence) return;
		if (memory.queue?.sentence === result.text) return;
		memory.setQueue({
			sentence: result.text,
			reader: result.reader,
			spans: result.spans,
			index: 0,
			items: [
				{
					status: result.status,
					draft: result.draft,
					issues: result.issues,
					shares: result.shares,
					idempotencyKey: crypto.randomUUID(),
					occurredAt: new Date().toISOString(),
				},
				...result.moreDrafts.map((item) => ({
					...item,
					idempotencyKey: crypto.randomUUID(),
					occurredAt: new Date().toISOString(),
				})),
			],
		});
	}, [query.current, result, sentence, memory]);

	const activeQueue =
		sentence.trim() && memory.queue?.sentence === sentence
			? memory.queue
			: null;
	const activeIndex = activeQueue?.index ?? 0;
	const items = activeQueue?.items ?? [];
	const activeItem = items[activeIndex];
	const activeDraft: ParseDraft | null = activeItem
		? activeItem.categoryOverride
			? { ...activeItem.draft, ...activeItem.categoryOverride }
			: activeItem.draft
		: null;

	const okPreview =
		activeQueue && activeItem?.status === "ok" && activeDraft
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
			activeQueue &&
			activeItem &&
			activeDraft &&
			activeItem.status !== "ok" &&
			!isRuleInteractiveQuestion(activeItem, activeQueue.reader) &&
			(memory.draft?.sentence !== activeQueue.sentence ||
				memory.draft?.itemIndex !== activeIndex)
		) {
			memory.setDraft({
				sentence: activeQueue.sentence,
				itemIndex: activeIndex,
				draft: activeDraft,
				issues: activeItem.issues,
				spans: activeQueue.reader === "ai" ? [] : activeQueue.spans,
			});
			router.replace(`/g/${groupId}/tx/new?form`);
		}
	}, [
		activeQueue,
		activeItem,
		activeDraft,
		activeIndex,
		memory,
		router,
		groupId,
	]);

	const setActiveCategory = (
		category: ParseDraft["category"],
		categoryId: string | null,
	) => {
		if (!activeQueue) return;
		memory.setQueue({
			...activeQueue,
			items: activeQueue.items.map((item, idx) =>
				idx === activeIndex
					? { ...item, categoryOverride: { category, categoryId } }
					: item,
			),
		});
	};

	const activeCardResult: ParseResponse | undefined =
		activeQueue && activeItem && activeDraft
			? {
					status: activeItem.status,
					text: activeQueue.sentence,
					draft: activeDraft,
					issues: activeItem.issues,
					shares:
						(preview.current ? preview.data?.shares : undefined) ??
						activeItem.shares,
					spans: activeQueue.reader === "ai" ? [] : activeQueue.spans,
					reader: activeQueue.reader,
					moreDrafts: [],
				}
			: undefined;

	const edit = (chosen?: ParseResponse) => {
		if (!activeQueue || !activeItem || !activeDraft) return;
		memory.setDraft({
			sentence: activeQueue.sentence,
			itemIndex: activeIndex,
			draft: chosen?.draft ?? activeDraft,
			issues: activeItem.issues,
			spans: activeQueue.reader === "ai" ? [] : activeQueue.spans,
		});
		router.push(`/g/${groupId}/tx/new?form`);
	};
	const skip = () => {
		if (saving.current || mutation.isPending || !activeQueue) return;
		if (activeIndex < items.length - 1) {
			memory.setQueue({ ...activeQueue, index: activeIndex + 1 });
			memory.setDraft(null);
			return;
		}
		memory.clear();
		router.replace(`/g/${groupId}`);
	};
	const save = (chosen?: ParseResponse) => {
		const savingResult = chosen ?? activeCardResult;
		if (
			savingResult?.status !== "ok" ||
			!activeQueue ||
			!activeItem ||
			saving.current
		)
			return;
		const parsed = CreateTransactionRequest.safeParse({
			...savingResult.draft,
			occurredAt: activeItem.occurredAt,
		});
		if (!parsed.success) return;
		saving.current = true;
		const nextQueue = {
			...activeQueue,
			items: activeQueue.items.map((item, idx) =>
				idx === activeIndex ? { ...item, submittedRequest: parsed.data } : item,
			),
		};
		memory.setQueue(nextQueue);
		mutation.mutate(
			{ request: parsed.data, key: activeItem.idempotencyKey },
			{
				onSuccess: () => {
					if (activeIndex < items.length - 1) {
						saving.current = false;
						memory.setQueue({ ...nextQueue, index: activeIndex + 1 });
						memory.setDraft(null);
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
	const handleSentenceChange = (next: string) => {
		if (next === sentence) return;
		if (next !== memory.queue?.sentence) {
			memory.setQueue(null);
			memory.setDraft(null);
		}
		setSentence(next);
	};
	const handleSend = () => {
		memory.setQueue(null);
		memory.setDraft(null);
		query.send();
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
	const isStaleQuery =
		query.isFetching && (!activeQueue || activeQueue.sentence !== sentence);
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
				activeQueue &&
				isRuleInteractiveQuestion(activeItem, activeQueue.reader) ? (
					<QuestionCard
						writerMemberId={writerMemberId}
						key={`${activeQueue.sentence}:${activeIndex}`}
						result={activeCardResult}
						members={members}
						categories={categories}
						groupId={groupId}
						onChangeCategory={setActiveCategory}
						onEdit={edit}
						onSave={save}
						disabled={isStaleQuery || mutation.isPending}
					/>
				) : activeCardResult?.status === "ok" && activeQueue ? (
					<ConfirmationCard
						key={`${activeQueue.sentence}:${activeIndex}`}
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
						disabled={isStaleQuery || mutation.isPending}
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
					if (activeQueue && activeItem && activeDraft)
						memory.setDraft({
							sentence: activeQueue.sentence,
							itemIndex: activeIndex,
							draft: activeDraft,
							issues: activeItem.issues,
							spans: activeQueue.reader === "ai" ? [] : activeQueue.spans,
						});
					else {
						memory.setQueue(null);
						memory.setDraft(null);
					}
				}}
				className="min-h-11 text-center font-bold"
			>
				{vi.feed.manualEntry}
			</Link>
			<div className="mt-auto flex items-end gap-3 rounded-[30px] border-[3px] border-ink bg-surface p-3">
				<SentenceInput
					text={sentence}
					spans={
						activeQueue && activeQueue.reader !== "ai" ? activeQueue.spans : []
					}
					onChange={handleSentenceChange}
					onSend={handleSend}
				/>
				<OnlineButton
					type="button"
					aria-label={vi.compose.send}
					onClick={handleSend}
					disabled={!sentence.trim()}
					className="flex size-[52px] shrink-0 items-center justify-center rounded-[20px] bg-ink text-surface"
				>
					<Icon name="send" size={24} />
				</OnlineButton>
			</div>
		</div>
	);
}
