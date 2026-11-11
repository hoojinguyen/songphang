import type { ColorCode, ShapeCode } from "../components/ui/MemberShape";

const SHAPES = [
	{ shape: "circle", color: "mint" },
	{ shape: "diamond", color: "sky" },
	{ shape: "squircle", color: "coral" },
	{ shape: "leaf", color: "lilac" },
] as const;
export function devShapeFor(index: number): {
	shape: ShapeCode;
	color: ColorCode;
} {
	return SHAPES[index % 4] ?? SHAPES[0];
}
