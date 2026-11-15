import { vi } from "../../messages/vi";
import { MemberShape } from "./MemberShape";

const SHAPES = [
	{
		shape: "circle",
		color: "mint",
		size: 112,
		left: 6,
		top: 24,
		name: vi.showcase.members.minh,
	},
	{
		shape: "diamond",
		color: "sky",
		size: 100,
		left: 104,
		top: 0,
		name: vi.showcase.members.lan,
	},
	{
		shape: "squircle",
		color: "coral",
		size: 88,
		left: 136,
		top: 100,
		name: vi.showcase.members.hung,
	},
	{
		shape: "leaf",
		color: "lilac",
		size: 74,
		left: 44,
		top: 140,
		name: vi.showcase.members.thu,
	},
] as const;
export function LoginShapes() {
	return (
		<div aria-hidden="true" className="relative mx-auto h-[220px] w-[260px]">
			{SHAPES.map((member) => (
				<span
					key={member.name}
					className="absolute"
					style={{ left: member.left, top: member.top }}
				>
					<MemberShape {...member} />
				</span>
			))}
		</div>
	);
}
