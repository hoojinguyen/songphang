import type { TransactionDto } from "@songphang/contract";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
export function ConflictNotice({
	current,
	onReload,
}: {
	current: TransactionDto;
	onReload: () => void;
}) {
	return (
		<aside
			role="alert"
			className="grid gap-3 rounded-[26px] bg-phrase-amount p-4"
		>
			<p>
				{t(vi.expenseForm.conflict, {
					name: current.updatedBy?.name ?? vi.expenseForm.someone,
				})}
			</p>
			<Button variant="primary" onClick={onReload}>
				{vi.expenseForm.reloadCurrent}
			</Button>
		</aside>
	);
}
