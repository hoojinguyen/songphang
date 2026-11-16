import { OnlineButton } from "./OnlineButton";
export function Switch({
	checked,
	onChange,
	label,
	disabled = false,
}: {
	checked: boolean;
	onChange: (checked: boolean) => void;
	label: string;
	disabled?: boolean;
}) {
	return (
		<OnlineButton
			type="button"
			role="switch"
			aria-checked={checked}
			aria-label={label}
			disabled={disabled}
			onClick={() => onChange(!checked)}
			className={`flex h-11 w-16 shrink-0 items-center rounded-[22px] p-1 disabled:opacity-60 ${checked ? "justify-end bg-ink" : "justify-start bg-sunken"}`}
		>
			<span
				className={`size-9 rounded-pill ${checked ? "bg-accent" : "bg-surface"}`}
			/>
		</OnlineButton>
	);
}
