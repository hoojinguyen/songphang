"use client";
import {
	type MemberColorCode,
	type MemberShapeCode,
	nextMemberAppearance,
} from "@songphang/contract";
import { useState } from "react";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { MemberShape } from "../ui/MemberShape";
export function NewMemberRow({
	usedPairs,
	position,
	onAdd,
	disabled = false,
	label = vi.newGroup.newMemberLabel,
	addLabel = vi.newGroup.add,
}: {
	usedPairs: readonly { shape: MemberShapeCode; color: MemberColorCode }[];
	position: number;
	onAdd: (name: string) => void;
	disabled?: boolean;
	label?: string;
	addLabel?: string;
}) {
	const [name, setName] = useState("");
	const appearance = nextMemberAppearance(usedPairs, position);
	const add = () => {
		if (!name.trim() || disabled) return;
		onAdd(name.trim());
		setName("");
	};
	return (
		<div className="flex items-center gap-2 rounded-[30px] border-[3px] border-ink bg-surface p-2">
			<MemberShape {...appearance} name={name} size={44} />
			<input
				aria-label={label}
				value={name}
				maxLength={50}
				disabled={disabled}
				onChange={(event) => setName(event.target.value)}
				onKeyDown={(event) => {
					if (event.key === "Enter") {
						event.preventDefault();
						add();
					}
				}}
				className="min-w-0 flex-1 bg-transparent text-[18px] font-extrabold outline-none"
			/>
			<Button
				variant="surface"
				onClick={add}
				disabled={disabled || !name.trim()}
			>
				{addLabel}
			</Button>
		</div>
	);
}
