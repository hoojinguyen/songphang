"use client";
import { BANKS } from "@songphang/contract";
import { foldVietnamese } from "@songphang/core";
import { useRef, useState } from "react";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { TextField } from "../ui/TextField";
export function BankPicker({
	value,
	onChange,
	disabled,
}: {
	value: string;
	onChange: (bin: string) => void;
	disabled: boolean;
}) {
	const dialog = useRef<HTMLDialogElement>(null);
	const opener = useRef<HTMLButtonElement>(null);
	const [query, setQuery] = useState("");
	const close = () => {
		dialog.current?.close();
		opener.current?.focus();
	};
	const selected = BANKS.find((bank) => bank.bin === value);
	return (
		<div className="grid gap-2">
			<span className="text-[13px] font-semibold text-muted">
				{vi.payment.bank}
			</span>
			<button
				ref={opener}
				type="button"
				disabled={disabled}
				aria-haspopup="dialog"
				onClick={() => {
					setQuery("");
					dialog.current?.showModal();
				}}
				className="min-h-14 rounded-[26px] bg-bg px-4 text-left font-bold"
			>
				{selected?.shortName ?? vi.payment.bank}
			</button>
			<dialog
				ref={dialog}
				aria-label={vi.payment.bank}
				onCancel={(event) => {
					event.preventDefault();
					close();
				}}
				className="m-auto w-[calc(100%-40px)] max-w-[390px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
			>
				<TextField
					label={vi.payment.bank}
					value={query}
					onChange={(event) => setQuery(event.target.value)}
					maxLength={100}
				/>
				<div className="my-4 grid max-h-[60dvh] gap-2 overflow-y-auto">
					{BANKS.filter((bank) =>
						foldVietnamese(
							`${bank.shortName} ${bank.name} ${bank.bin}`,
						).includes(foldVietnamese(query.trim())),
					).map((bank) => (
						<button
							key={bank.bin}
							type="button"
							onClick={() => {
								onChange(bank.bin);
								close();
							}}
							className="min-h-14 rounded-[20px] bg-surface p-3 text-left"
						>
							<strong className="block">{bank.shortName}</strong>
							<span className="text-xs">
								{bank.name} · {bank.bin}
							</span>
						</button>
					))}
				</div>
				<Button variant="surface" allowOffline onClick={close}>
					{vi.common.cancel}
				</Button>
			</dialog>
		</div>
	);
}
