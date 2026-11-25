import type { NextConfig } from "next";
import { z } from "zod";

const apiOrigin = z
	.url({ protocol: /^https?$/, hostname: /.+/ })
	.max(2048)
	.refine((value) => {
		const url = URL.parse(value);
		return (
			url !== null &&
			url.username === "" &&
			url.password === "" &&
			url.pathname === "/" &&
			url.search === "" &&
			url.hash === ""
		);
	})
	.safeParse(process.env.API_ORIGIN ?? "http://localhost:4000");
if (!apiOrigin.success)
	throw new Error("API_ORIGIN must be a valid HTTP(S) origin");

function parseDevHostname(rawValue: string): string | null {
	const trimmed = rawValue.trim();
	if (trimmed.length === 0 || trimmed.includes("*")) {
		return null;
	}
	const candidate = trimmed.includes("://") ? trimmed : `http://${trimmed}`;
	const url = URL.parse(candidate);
	if (
		url === null ||
		(url.protocol !== "http:" && url.protocol !== "https:") ||
		url.hostname.length === 0 ||
		url.hostname.includes("*") ||
		url.username !== "" ||
		url.password !== "" ||
		url.pathname !== "/" ||
		url.search !== "" ||
		url.hash !== ""
	) {
		return null;
	}
	return url.hostname.toLowerCase();
}

function resolveAllowedDevOrigins(): string[] | undefined {
	if (process.env.NODE_ENV !== "development") {
		return undefined;
	}
	const origins = new Set<string>();
	const webOrigin = process.env.WEB_ORIGIN;
	if (webOrigin) {
		const host = parseDevHostname(webOrigin);
		if (host) origins.add(host);
	}
	const extraOrigins = process.env.ALLOWED_DEV_ORIGINS;
	if (extraOrigins) {
		for (const item of extraOrigins.split(",")) {
			const host = parseDevHostname(item);
			if (host) origins.add(host);
		}
	}
	return origins.size > 0 ? [...origins] : undefined;
}

const allowedDevOrigins = resolveAllowedDevOrigins();

const nextConfig: NextConfig = {
	agentRules: false,
	...(allowedDevOrigins ? { allowedDevOrigins } : {}),
	async rewrites() {
		return [
			{ source: "/api/:path*", destination: `${apiOrigin.data}/api/:path*` },
		];
	},
};

export default nextConfig;
