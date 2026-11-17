"use client";
import { create } from "qrcode";
import { useMemo } from "react";

export function QrCard({
	payload,
	label,
	hint,
}: {
	payload: string;
	label: string;
	hint: string;
}) {
	const matrix = useMemo(
		() => create(payload, { errorCorrectionLevel: "M" }).modules,
		[payload],
	);
	const path = Array.from(matrix.data, (value, index) =>
		value
			? `M${(index % matrix.size) + 4} ${Math.floor(index / matrix.size) + 4}h1v1h-1z`
			: "",
	).join("");
	return (
		<section className="grid justify-items-center gap-3 rounded-card bg-surface p-5">
			<svg
				role="img"
				aria-label={label}
				width={240}
				height={240}
				viewBox={`0 0 ${matrix.size + 8} ${matrix.size + 8}`}
				className="h-60 w-60 bg-surface text-ink"
				shapeRendering="crispEdges"
			>
				<title>{label}</title>
				<path d={path} fill="currentColor" />
			</svg>
			<p className="text-center text-xs text-muted">{hint}</p>
		</section>
	);
}
