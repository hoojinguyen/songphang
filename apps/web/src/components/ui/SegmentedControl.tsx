export function SegmentedControl({
	label,
	options,
	value,
	onChange,
	disabled,
}: {
	label: string;
	options: Array<{ value: string; label: string }>;
	value: string;
	onChange: (value: string) => void;
	disabled?: boolean;
}) {
	return (
		<fieldset aria-label={label} className="flex rounded-[18px] bg-sunken p-1">
			{options.map((option) => (
				<button
					key={option.value}
					type="button"
					aria-pressed={value === option.value}
					disabled={disabled}
					onClick={() => onChange(option.value)}
					className={`min-h-11 flex-1 rounded-[18px] px-3 text-sm font-bold disabled:opacity-60 ${value === option.value ? "bg-ink text-surface" : "text-ink"}`}
				>
					{option.label}
				</button>
			))}
		</fieldset>
	);
}
