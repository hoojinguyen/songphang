import { z } from "@hono/zod-openapi";
export const MemberShapeCode = z.enum([
	"circle",
	"diamond",
	"squircle",
	"leaf",
]);
export type MemberShapeCode = z.infer<typeof MemberShapeCode>;
export const MemberColorCode = z.enum(["mint", "sky", "coral", "lilac"]);
export type MemberColorCode = z.infer<typeof MemberColorCode>;
type Appearance = { shape: MemberShapeCode; color: MemberColorCode };
const SHAPES = MemberShapeCode.options;
const COLORS = MemberColorCode.options;
export const MEMBER_APPEARANCES: readonly Appearance[] = Array.from(
	{ length: 16 },
	(_, index) => ({
		shape: SHAPES[index % 4] ?? "circle",
		color: COLORS[(index + Math.floor(index / 4)) % 4] ?? "mint",
	}),
);
export function nextMemberAppearance(
	usedPairs: readonly Appearance[],
	position: number,
): Appearance {
	const unused = MEMBER_APPEARANCES.find(
		(pair) =>
			!usedPairs.some(
				(used) => used.shape === pair.shape && used.color === pair.color,
			),
	);
	const pair = unused ?? MEMBER_APPEARANCES[position % 16];
	if (pair === undefined) throw new RangeError("Invalid member position");
	return { ...pair };
}
export const MemberName = z.string().trim().min(1).max(50);
export const MemberDto = z
	.object({
		id: z.uuid(),
		name: MemberName,
		active: z.boolean(),
		defaultWeight: z.string(),
		position: z.int().nonnegative(),
		shape: MemberShapeCode,
		color: MemberColorCode,
		isMe: z.boolean(),
	})
	.openapi("MemberDto");
export type MemberDto = z.infer<typeof MemberDto>;
