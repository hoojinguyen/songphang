"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
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
import { useDraft } from "../../../../../lib/draft-context";
import { useParseSentence } from "../../../../../lib/quick-entry";
import { useCreateTransaction } from "../../../../../lib/transactions";
import { vi } from "../../../../../messages/vi";
export function ComposeScreen({
	groupId,
	groupName,
	members,
}: {
	groupId: string;
	groupName: string;
	members: MemberDto[];
}) {
	const memory = useDraft();
	const { sentence, setSentence } = memory;
	const query = useParseSentence(groupId, sentence);
	const mutation = useCreateTransaction(groupId);
	const router = useRouter();
	const keys = useRef(new Map<string, { key: string; occurredAt: string }>());
	const saving = useRef(false);
	const [collapsing, setCollapsing] = useState(false);
	const result = sentence.trim() ? query.data : undefined;
	useEffect(() => {
		if (
			query.current &&
			result?.status === "unparsed" &&
			memory.draft?.sentence !== sentence
		) {
			memory.setDraft({
				sentence,
				draft: result.draft,
				issues: result.issues,
				spans: result.spans,
			});
			router.replace(`/g/${groupId}/tx/new?form`);
		}
	}, [query.current, result, memory, sentence, router, groupId]);
	const edit = (chosen?: ParseResponse) => {
		if (result?.text !== sentence) return;
		if (result)
			memory.setDraft({
				sentence,
				draft: chosen?.draft ?? result.draft,
				issues: result.issues,
				spans: result.spans,
			});
		router.push(`/g/${groupId}/tx/new?form`);
	};
	const save = (chosen?: ParseResponse) => {
		const savingResult = chosen ?? result;
		if (savingResult?.status !== "ok" || !query.current || saving.current)
			return;
		let identity = keys.current.get(sentence);
		if (!identity) {
			identity = {
				key: crypto.randomUUID(),
				occurredAt: new Date().toISOString(),
			};
			keys.current.set(sentence, identity);
		}
		const parsed = CreateTransactionRequest.safeParse({
			...savingResult.draft,
			occurredAt: identity.occurredAt,
			category: null,
		});
		if (!parsed.success) return;
		saving.current = true;
		mutation.mutate(
			{ request: parsed.data, key: identity.key },
			{
				onSuccess: () => {
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
				{result?.status === "needs_input" ? (
					<QuestionCard
						key={result.text}
						result={result}
						members={members}
						groupId={groupId}
						onEdit={edit}
						onSave={save}
						disabled={!query.current || mutation.isPending}
					/>
				) : result?.status === "ok" ? (
					<ConfirmationCard
						result={result}
						members={members}
						onEdit={() => edit()}
						onSave={() => save()}
						disabled={!query.current || mutation.isPending}
					/>
				) : null}
			</div>
			{query.isError && <p role="alert">{vi.common.loadError}</p>}
			{mutation.isError && <p role="alert">{vi.common.saveError}</p>}
			<Link
				href={`/g/${groupId}/tx/new?form`}
				onClick={() => {
					if (result?.text === sentence)
						memory.setDraft({
							sentence,
							draft: result.draft,
							issues: result.issues,
							spans: result.spans,
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
					spans={result?.text === sentence ? result.spans : []}
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
