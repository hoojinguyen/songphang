"use client";
import { HealthResponse } from "@songphang/contract";
import { onlineManager, useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef } from "react";
import { requestSucceeded } from "../../lib/network-state";
import { useConnection } from "../../lib/use-online";
import { t, vi } from "../../messages/vi";
import { Icon } from "./Icon";
export function OfflineBanner() {
	const { online, since } = useConnection();
	const client = useQueryClient();
	const previous = useRef(online);
	useEffect(() => {
		onlineManager.setOnline(online);
		if (online && !previous.current) void client.invalidateQueries();
		previous.current = online;
		if (online) return;
		const controller = new AbortController();
		const probe = async () => {
			if (!navigator.onLine) return;
			try {
				const response = await fetch("/api/v1/health", {
					cache: "no-store",
					signal: controller.signal,
				});
				const body: unknown = await response.json();
				if (response.ok && HealthResponse.safeParse(body).success)
					requestSucceeded();
			} catch {}
		};
		const timer = setInterval(() => {
			void probe();
		}, 5000);
		return () => {
			clearInterval(timer);
			controller.abort();
		};
	}, [online, client]);
	if (online) return null;
	return (
		<aside
			role="status"
			className="mx-auto flex max-w-[390px] items-center gap-3 rounded-[22px] bg-ink px-4 py-3 text-[13px] font-bold text-white"
		>
			<Icon name="wifi-off" size={22} />
			<div>
				{vi.offline.banner}
				{since !== null && (
					<p className="text-on-ink-muted">
						{t(vi.offline.since, {
							time: new Date(since).toLocaleTimeString("vi-VN", {
								hour: "2-digit",
								minute: "2-digit",
							}),
						})}
					</p>
				)}
			</div>
		</aside>
	);
}
