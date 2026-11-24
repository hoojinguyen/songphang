import { type InputHTMLAttributes, useId } from "react";
export function TextField({
	label,
	type = "text",
	error,
	hint,
	id,
	...props
}: {
	label: string;
	type?: "text" | "email" | "password";
	error?: string;
	hint?: string;
} & InputHTMLAttributes<HTMLInputElement>) {
	const generated = useId();
	const fieldId = id ?? generated;
	const descriptionId = `${fieldId}-description`;
	return (
		<div className="grid gap-2 text-[13px] font-semibold text-muted">
			<label htmlFor={fieldId}>{label}</label>
			<input
				{...props}
				id={fieldId}
				type={type}
				aria-invalid={error ? true : undefined}
				aria-describedby={error || hint ? descriptionId : undefined}
				className={`h-14 min-w-0 w-full rounded-[26px] bg-surface px-4 text-[17px] font-bold text-ink placeholder:text-placeholder ${props.className ?? ""}`}
			/>
			{error ? (
				<span id={descriptionId} role="alert" className="text-[13px]">
					{error}
				</span>
			) : hint ? (
				<span id={descriptionId} className="text-[13px]">
					{hint}
				</span>
			) : null}
		</div>
	);
}
