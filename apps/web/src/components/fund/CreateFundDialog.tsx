"use client";
import type { MemberDto } from "@songphang/contract";
import { useEffect, useId, useRef, useState } from "react";
import { useCreateFund } from "../../lib/fund";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";

export function CreateFundDialog({
	open,
	groupId,
	people,
	onClose,
}: {
	open: boolean;
	groupId: string;
	people: MemberDto[];
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const [name, setName] = useState<string>(vi.fund.defaultName);
	const [holderMemberId, setHolderMemberId] = useState<string | null>(
		people[0]?.id ?? null,
	);
	const [key, setKey] = useState(() => crypto.randomUUID());
	const create = useCreateFund(groupId);
	useSessionGuard(create.error);

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			setName(vi.fund.defaultName);
			setHolderMemberId(people[0]?.id ?? null);
			setKey(crypto.randomUUID());
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open, people]);

	const submit = () => {
		const trimmed = name.trim();
		if (!trimmed || create.isPending) return;
		create.mutate(
			{
				request: {
					name: trimmed,
					...(holderMemberId ? { holderMemberId } : {}),
				},
				key,
			},
			{
				onSuccess: () => onClose(),
				onError: () => setKey(crypto.randomUUID()),
			},
		);
	};

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto w-[calc(100%-32px)] max-w-[398px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
		>
			<div className="grid gap-4">
				<h2 id={titleId} className="text-lg font-black">
					{vi.fund.createEntry}
				</h2>
				<label className="grid gap-1 text-xs font-bold text-muted">
					{vi.fund.nameLabel}
					<input
						value={name}
						maxLength={50}
						onChange={(event) => setName(event.target.value)}
						className="h-12 min-w-0 rounded-[20px] bg-surface px-3 text-base font-bold text-ink"
					/>
				</label>
				<div className="grid gap-2">
					<span className="text-xs font-bold text-muted">
						{vi.fund.holderLabel}
					</span>
					<div className="flex flex-wrap gap-1.5">
						<button
							type="button"
							aria-pressed={holderMemberId === null}
							onClick={() => setHolderMemberId(null)}
							className={`min-h-11 rounded-pill px-3 text-xs font-bold ${
								holderMemberId === null
									? "bg-ink text-surface"
									: "bg-surface text-ink"
							}`}
						>
							{vi.fund.noHolder}
						</button>
						{people.map((person) => (
							<button
								key={person.id}
								type="button"
								aria-pressed={holderMemberId === person.id}
								onClick={() => setHolderMemberId(person.id)}
								className={`min-h-11 rounded-pill px-3 text-xs font-bold ${
									holderMemberId === person.id
										? "bg-ink text-surface"
										: "bg-surface text-ink"
								}`}
							>
								{person.name}
							</button>
						))}
					</div>
				</div>
				{create.isError && (
					<p role="alert" className="text-sm font-bold">
						{create.error.status === 403
							? vi.common.forbidden
							: vi.common.saveError}
					</p>
				)}
				<div className="flex gap-2">
					<Button
						variant="surface"
						allowOffline
						className="flex-1"
						onClick={onClose}
					>
						{vi.common.cancel}
					</Button>
					<Button
						variant="accent"
						className="flex-1"
						disabled={create.isPending || !name.trim()}
						onClick={submit}
					>
						{vi.fund.createSubmit}
					</Button>
				</div>
			</div>
		</dialog>
	);
}
