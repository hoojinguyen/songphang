"use client";
import { allocateByWeights } from "@songphang/core";
import { useEffect, useRef, useState } from "react";
export function useCountedBalance(target: number) {
	const [display, setDisplay] = useState(target);
	const current = useRef(target);
	useEffect(() => {
		const motion = window.matchMedia("(prefers-reduced-motion: no-preference)");
		const from = current.current;
		const difference = target - from;
		const started = performance.now();
		let frame = 0;
		const finish = () => {
			cancelAnimationFrame(frame);
			current.current = target;
			setDisplay(target);
		};
		if (!motion.matches) {
			finish();
			return;
		}
		const tick = (now: number) => {
			const elapsed = Math.min(400, Math.max(0, Math.round(now - started)));
			const part =
				allocateByWeights(Math.abs(difference), [
					BigInt(elapsed),
					BigInt(400 - elapsed),
				])[0] ?? 0;
			const value = from + (difference < 0 ? -Number(part) : Number(part));
			current.current = value;
			setDisplay(value);
			if (elapsed < 400) frame = requestAnimationFrame(tick);
		};
		frame = requestAnimationFrame(tick);
		motion.addEventListener("change", finish);
		return () => {
			cancelAnimationFrame(frame);
			motion.removeEventListener("change", finish);
		};
	}, [target]);
	return display;
}
