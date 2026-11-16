import { vi } from "../../messages/vi";
import { TextField } from "../ui/TextField";
export function DescriptionPrompt({
	value,
	onChange,
}: {
	value: string;
	onChange: (s: string) => void;
}) {
	return (
		<TextField
			label={vi.compose.descriptionPrompt}
			value={value}
			maxLength={200}
			onChange={(e) => onChange(e.target.value)}
		/>
	);
}
