"use client";
import { GroupEventNotification } from "@songphang/contract";
import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { z } from "zod";

import { requestFailed } from "./network-state";
import { useOnline } from "./use-online";

const Resources = z.object({
	resources: GroupEventNotification.shape.resources,
});
export function useGroupEvents(groupId: string) {
	const online = useOnline();
	const client = useQueryClient();
	const router = useRouter();
	useEffect(() => {
		if (!online) return;
		const source = new EventSource(
			`/api/v1/groups/${encodeURIComponent(groupId)}/events`,
		);
		let failed = false;
		source.onerror = () => {
			requestFailed();
			failed = true;
		};
		source.onopen = () => {
			if (failed) {
				void client.invalidateQueries({ queryKey: ["group", groupId] });
				void client.invalidateQueries({ queryKey: ["groups"] });
				void client.invalidateQueries({ queryKey: ["notifications"] });
				failed = false;
			}
		};
		source.addEventListener("changed", (event: MessageEvent<unknown>) => {
			if (typeof event.data !== "string" || event.data.length > 2048) return;
			try {
				const payload = Resources.safeParse(JSON.parse(event.data));
				if (!payload.success) return;
				for (const resource of payload.data.resources) {
					void client.invalidateQueries({
						queryKey:
							resource === "group"
								? ["group", groupId]
								: ["group", groupId, resource],
						exact: resource === "group",
					});
					if (resource === "settlementRequests") {
						void client.invalidateQueries({
							queryKey: ["group", groupId, "balances"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "settlement-vault"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "breakdowns"],
						});
					}
					if (resource === "transactions") {
						void client.invalidateQueries({
							queryKey: ["group", groupId, "stats"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "settlement-vault"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "breakdowns"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "settlementCycles"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "recurringExpenses"],
						});
						void client.invalidateQueries({ queryKey: ["me", "overview"] });
					}
					if (resource === "recurringExpenses") {
						void client.invalidateQueries({ queryKey: ["me", "overview"] });
					}
					if (resource === "households") {
						void client.invalidateQueries({
							queryKey: ["group", groupId, "members"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "balances"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "breakdowns"],
						});
						void client.invalidateQueries({ queryKey: ["me", "overview"] });
					}
					if (resource === "settlementCycles") {
						void client.invalidateQueries({
							queryKey: ["group", groupId, "transactions"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "balances"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "breakdowns"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "settlement-vault"],
						});
					}
				}
				void client.invalidateQueries({
					queryKey: ["group", groupId, "invite"],
				});
				void client.invalidateQueries({ queryKey: ["groups"] });
				void client.invalidateQueries({ queryKey: ["notifications"] });
			} catch {
				return;
			}
		});
		source.addEventListener("removed", () => {
			source.close();
			if (client.getQueryData(["deleting", groupId]) === true) return;
			void client.cancelQueries({ queryKey: ["group", groupId] }).then(() => {
				client.removeQueries({ queryKey: ["group", groupId] });
				client.setQueryData(["notice", "removed"], true);
				void client.invalidateQueries({ queryKey: ["groups"] });
				router.replace("/");
			});
		});
		return () => source.close();
	}, [client, groupId, router, online]);
}
