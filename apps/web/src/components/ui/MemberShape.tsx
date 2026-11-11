export type ShapeCode = "circle" | "diamond" | "squircle" | "leaf";
export type ColorCode = "mint" | "sky" | "coral" | "lilac";

const COLORS: Record<ColorCode, string> = {
	mint: "bg-mint",
	sky: "bg-sky",
	coral: "bg-coral",
	lilac: "bg-lilac",
};
const SHAPES = {
	circle: { scale: 1, radius: "50%", rotation: 0 },
	diamond: { scale: 0.72, radius: "24%", rotation: 45 },
	squircle: { scale: 1, radius: "38%", rotation: 0 },
	leaf: { scale: 0.86, radius: "50% 10% 50% 10%", rotation: 0 },
} as const;

type MemberShapeProps = {
	shape: ShapeCode;
	color: ColorCode;
	size: number;
	name: string;
	showInitial?: boolean;
};

export function MemberShape({
	shape,
	color,
	size,
	name,
	showInitial,
}: MemberShapeProps) {
	const geometry = SHAPES[shape];
	const initial = Array.from(name.trim())[0]?.toLocaleUpperCase("vi");
	return (
		<span
			role="img"
			aria-label={name}
			className="inline-flex shrink-0 items-center justify-center"
			style={{ width: size, height: size }}
		>
			<span
				className={`flex items-center justify-center text-ink ${COLORS[color]}`}
				style={{
					width: size * geometry.scale,
					height: size * geometry.scale,
					borderRadius: geometry.radius,
					transform: `rotate(${geometry.rotation}deg)`,
				}}
			>
				{showInitial !== false && size >= 44 && (
					<span
						aria-hidden="true"
						className="font-black"
						style={{
							fontSize: size * 0.36,
							transform: `rotate(${-geometry.rotation}deg)`,
						}}
					>
						{initial}
					</span>
				)}
			</span>
		</span>
	);
}
