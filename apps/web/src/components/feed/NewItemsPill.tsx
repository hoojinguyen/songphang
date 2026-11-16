import { vi } from "../../messages/vi";
export function NewItemsPill({ onClick }: { onClick: () => void }) {
	return (
		<button
			type="button"
			onClick={onClick}
			className="fixed bottom-[112px] left-1/2 z-10 h-11 -translate-x-1/2 rounded-[22px] bg-ink px-5 text-sm font-bold text-surface"
		>
			{vi.feed.newItems}
		</button>
	);
}
