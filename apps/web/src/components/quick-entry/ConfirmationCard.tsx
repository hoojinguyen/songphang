import type { MemberDto, ParseResponse } from "@songphang/contract";
import type { ReactNode } from "react";
import { formatAmount, formatCompactAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ShareShapes } from "./ShareShapes";
export function ConfirmationCard({
	result,
	members,
	onEdit,
	onSave,
	disabled,
	children,
	saveLabel,
}: {
	result: ParseResponse;
	members: MemberDto[];
	onEdit: () => void;
	onSave: () => void;
	disabled: boolean;
	children?: ReactNode;
	saveLabel?: string;
}) {
	const { draft, shares = [] } = result;
	const payer = members.find((m) => m.id === draft.payers[0]?.memberId);
	const split = draft.split;
	const name = (id: string) => members.find((m) => m.id === id)?.name ?? "";
	const equal = shares.every((s) => s.amount === shares[0]?.amount);
	const notIncluded = members.filter(
		(m) => m.active && !shares.some((s) => s.memberId === m.id),
	);
	const rest =
		split?.method === "exact" && draft.amount !== null
			? draft.amount - split.entries.reduce((n, e) => n + e.amount, 0)
			: 0;
	return (
		<section className="grid gap-4 rounded-[40px] bg-surface px-[18px] pb-[18px] pt-5">
			<p className="text-[13px] font-semibold text-muted">
				{vi.compose.understood}
			</p>
			<h2 className="text-lg font-extrabold">{draft.description}</h2>
			{draft.amount !== null && (
				<p className="break-words text-[60px] font-black leading-tight">
					<mark className="rounded-xl bg-phrase-amount">
						{formatAmount(draft.amount)}
					</mark>{" "}
					<span className="text-[22px] text-muted">{vi.common.currency}</span>
				</p>
			)}
			<div className="flex flex-wrap gap-2 text-[13px] font-bold">
				{payer && (
					<span className="rounded-[14px] bg-phrase-payer px-3 py-[6px]">
						{result.spans.some((s) => s.kind === "payer")
							? t(vi.compose.payer, { name: payer.name })
							: vi.compose.payerDefault}
					</span>
				)}
				{shares.length > 0 && split && (
					<span className="rounded-[14px] bg-phrase-split px-3 py-[6px]">
						{split.method === "exact"
							? t(vi.compose.exact, {
									parts: split.entries
										.map(
											(e) =>
												`${name(e.memberId)} ${formatCompactAmount(e.amount)}`,
										)
										.join(" · "),
								})
							: t(equal ? vi.compose.equal : vi.compose.equalUneven, {
									count: String(shares.length),
									amount: formatAmount(shares[0]?.amount ?? 0),
								})}
					</span>
				)}
				{rest > 0 && (
					<span className="rounded-[14px] bg-phrase-rest px-3 py-[6px]">
						{t(vi.compose.rest, {
							amount: formatAmount(rest),
							count: String(shares.length),
						})}
					</span>
				)}
			</div>
			{shares.length > 0 && (
				<ShareShapes
					shares={shares.flatMap((s) => {
						const member = members.find((m) => m.id === s.memberId);
						return member ? [{ member, amount: s.amount }] : [];
					})}
				/>
			)}
			{children}
			<p className="text-xs text-muted">
				{shares.length > 0 && notIncluded.length > 0
					? t(vi.compose.notIncluded, {
							names: notIncluded.map((m) => m.name).join(", "),
						})
					: ""}{" "}
				{vi.compose.nothingSaved}
			</p>
			<div className="flex gap-3">
				<Button
					variant="surface"
					size="lg"
					onClick={onEdit}
					className="flex-1 bg-bg"
				>
					{vi.compose.edit}
				</Button>
				<Button
					variant="accent"
					size="lg"
					onClick={onSave}
					disabled={disabled}
					className="flex-[1.6] text-[17px] font-black"
				>
					{saveLabel ?? vi.compose.save}
				</Button>
			</div>
		</section>
	);
}
