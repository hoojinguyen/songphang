import { MEMBER_APPEARANCES } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { NewMemberRow } from "./NewMemberRow";
export function NewGroupMembers({
	creatorName,
	names,
	onChange,
	isPending,
}: {
	creatorName: string;
	names: Array<{ id: string; name: string }>;
	onChange: (names: Array<{ id: string; name: string }>) => void;
	isPending: boolean;
}) {
	const appearanceAt = (index: number) =>
		MEMBER_APPEARANCES[index % 16] ??
		({ shape: "circle", color: "mint" } as const);
	return (
		<>
			<h2 className="text-[17px] font-extrabold">{vi.newGroup.membersTitle}</h2>
			<div className="flex items-center gap-3">
				<MemberShape shape="circle" color="mint" size={44} name={creatorName} />
				<span className="flex-1 text-base font-extrabold">{creatorName}</span>
				<span>{vi.newGroup.creatorTag}</span>
			</div>
			{names.map((member, index) => (
				<div key={member.id} className="flex items-center gap-3">
					<MemberShape
						{...appearanceAt(index + 1)}
						size={44}
						name={member.name}
					/>
					<span className="min-w-0 flex-1 break-words font-extrabold">
						{member.name}
					</span>
					<button
						type="button"
						aria-label={t(vi.newGroup.removeMember, { name: member.name })}
						onClick={() =>
							onChange(names.filter((_, position) => position !== index))
						}
						className="flex size-11 items-center justify-center"
					>
						<Icon name="close" size={20} />
					</button>
				</div>
			))}
			<NewMemberRow
				position={names.length + 1}
				usedPairs={Array.from({ length: names.length + 1 }, (_, index) =>
					appearanceAt(index),
				)}
				onAdd={(memberName) =>
					onChange([...names, { id: crypto.randomUUID(), name: memberName }])
				}
				disabled={names.length >= 99 || isPending}
			/>
		</>
	);
}
