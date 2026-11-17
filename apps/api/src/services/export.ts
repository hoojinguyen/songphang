import { formatVietnamDateTime, toVietnamDate } from "@songphang/core";
import {
	listExportTransactions,
	listGroupCategories,
	listGroupLivePayers,
	listGroupLiveShares,
	listGroupMembers,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { serializeCsv } from "../csv.js";
import {
	CSV_CATEGORY_LABELS,
	CSV_HEADERS,
	CSV_TYPE_LABELS,
} from "../csv-labels.js";

export async function exportGroupCsv(deps: AppDeps, groupId: string) {
	const data = await deps.db.transaction(
		async (executor) => {
			const [members, categories, rows, payers, shares] = await Promise.all([
				listGroupMembers(executor, groupId),
				listGroupCategories(executor, groupId),
				listExportTransactions(executor, groupId),
				listGroupLivePayers(executor, groupId),
				listGroupLiveShares(executor, groupId),
			]);
			return { members, categories, rows, payers, shares };
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);

	const memberNames = new Map(data.members.map((m) => [m.id, m.name]));
	const categoryNames = new Map(data.categories.map((c) => [c.id, c.name]));

	const payersByTx = new Map<string, Array<{ name: string; amount: number }>>();
	for (const payer of data.payers) {
		const list = payersByTx.get(payer.transactionId) ?? [];
		list.push({
			name: memberNames.get(payer.memberId) ?? "",
			amount: payer.amount,
		});
		payersByTx.set(payer.transactionId, list);
	}

	const sharesByTx = new Map<string, Map<string, number>>();
	for (const share of data.shares) {
		const map =
			sharesByTx.get(share.transactionId) ?? new Map<string, number>();
		map.set(share.memberId, share.amount);
		sharesByTx.set(share.transactionId, map);
	}

	const header = [...CSV_HEADERS, ...data.members.map((member) => member.name)];
	const bodyRows = data.rows.map((row) => {
		const categoryLabel = row.category
			? (CSV_CATEGORY_LABELS[row.category] ?? "")
			: row.categoryId
				? (categoryNames.get(row.categoryId) ?? "")
				: "";
		const payerText = (payersByTx.get(row.id) ?? [])
			.map((entry) => `${entry.name} ${entry.amount}`)
			.join("; ");
		const txShares = sharesByTx.get(row.id);
		const memberCells = data.members.map((member) => {
			const amount = txShares?.get(member.id);
			return amount === undefined ? "" : amount;
		});
		return [
			formatVietnamDateTime(row.occurredAt),
			CSV_TYPE_LABELS[row.type] ?? row.type,
			row.description,
			categoryLabel,
			row.amount,
			payerText,
			...memberCells,
		];
	});

	const dateStamp = toVietnamDate(deps.now()).replaceAll("-", "");
	return {
		filename: `song-phang-${dateStamp}.csv`,
		content: serializeCsv([header, ...bodyRows]),
	};
}
