import { vi } from "../../messages/vi";
import { Button } from "./Button";
export function LoadError({
	onRetry,
	isRetrying,
}: {
	onRetry: () => void;
	isRetrying: boolean;
}) {
	return (
		<div role="alert" className="grid gap-3 text-center">
			<p>{vi.common.loadError}</p>
			<Button variant="primary" onClick={onRetry} disabled={isRetrying}>
				{vi.common.retry}
			</Button>
		</div>
	);
}
