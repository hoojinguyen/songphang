import { OnlineButton } from "./OnlineButton";
export function SegmentedControl({
	label,
	options,
	value,
	onChange,
	disabled,
	allowOffline = false,
}: {
	label: string;
	options: Array<{ value: string; label: string }>;
	value: string;
	onChange: (value: string) => void;
	disabled?: boolean;
	allowOffline?: boolean;
}) {
	return (
		<fieldset aria-label={label} className="flex rounded-[18px] bg-sunken p-1">
			{options.map((option) => (
				<OnlineButton
					key={option.value}
					type="button"
					allowOffline={allowOffline}
					aria-pressed={value === option.value}
					disabled={disabled}
					onClick={() => onChange(option.value)}
					className={`min-h-11 flex-1 rounded-[18px] px-2 text-[13px] font-bold leading-tight disabled:opacity-60 ${value === option.value ? "bg-ink text-on-ink" : "text-ink"}`}
				>
					{option.label}
				</OnlineButton>
			))}
		</fieldset>
	);
}
