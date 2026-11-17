"use client";
import type { BalancesResponse } from "@songphang/contract";
import Link from "next/link";
import { t, vi } from "../../messages/vi";
import { CopyRow } from "./CopyRow";
import { QrCard } from "./QrCard";

type Transfer = BalancesResponse["transfers"][number];

export function PayMethodsCard({
	groupId,
	transfer,
	toName,
	canAddDetails,
}: {
	groupId: string;
	transfer: Transfer;
	toName: string;
	canAddDetails: boolean;
}) {
	const bank = transfer.payTo.find((method) => method.kind === "bank");
	const wallets = transfer.payTo.filter((method) => method.kind !== "bank");
	if (transfer.payTo.length === 0) {
		return (
			<section className="grid justify-items-center gap-3 rounded-card bg-surface p-5 text-center">
				<p className="text-sm font-semibold text-muted">
					{t(vi.pay.noDetails, { to: toName })}
				</p>
				{canAddDetails && (
					<Link
						href={`/g/${encodeURIComponent(groupId)}/members`}
						className="inline-flex min-h-11 items-center justify-center rounded-pill bg-sunken px-5 text-sm font-bold text-ink"
					>
						{vi.pay.addDetails}
					</Link>
				)}
			</section>
		);
	}
	return (
		<div className="grid gap-4">
			{bank && (
				<>
					<QrCard
						payload={bank.qrPayload}
						label={t(vi.pay.title, { to: toName })}
						hint={vi.pay.qrHint}
					/>
					<section className="grid gap-2 rounded-card bg-surface p-5">
						<CopyRow label={vi.payment.bank} value={bank.bankShortName} />
						<CopyRow
							label={vi.payment.accountNumber}
							value={bank.accountNumber}
						/>
						<CopyRow label={vi.payment.accountName} value={bank.accountName} />
						<CopyRow label={vi.pay.purpose} value={transfer.purpose} />
					</section>
				</>
			)}
			{wallets.length > 0 && (
				<section className="grid gap-2 rounded-card bg-surface p-5">
					{wallets.map((wallet) => (
						<CopyRow
							key={wallet.kind}
							label=""
							value={t(
								wallet.kind === "momo" ? vi.pay.momoRow : vi.pay.zalopayRow,
								{ phone: wallet.phone },
							)}
							copyValue={wallet.phone}
						/>
					))}
				</section>
			)}
		</div>
	);
}
