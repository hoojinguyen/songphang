"use client";
import type { MemberDto } from "@songphang/contract";
import { vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";

export function ReceiptPayerPicker({
	payerOptions,
	payerId,
	onChange,
}: {
	payerOptions: MemberDto[];
	payerId: string | null;
	onChange: (memberId: string) => void;
}) {
	return (
		<section className="grid gap-2 rounded-[26px] bg-surface p-3">
			<h2 className="text-xs font-extrabold text-muted">
				{vi.receipts.paidBy}
			</h2>
			<div className="flex flex-wrap gap-2">
				{payerOptions.map((member) => {
					const activePayer = payerId === member.id;
					return (
						<button
							key={member.id}
							type="button"
							aria-pressed={activePayer}
							onClick={() => onChange(member.id)}
							className={`flex min-h-11 items-center gap-2 rounded-pill px-3 text-xs font-extrabold ${
								activePayer ? "bg-ink text-surface" : "bg-sunken text-ink"
							}`}
						>
							<MemberShape {...member} size={22} />
							{member.name}
						</button>
					);
				})}
			</div>
		</section>
	);
}
