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

const nextConfig: NextConfig = {
	agentRules: false,
	async rewrites() {
		return [
			{ source: "/api/:path*", destination: `${apiOrigin.data}/api/:path*` },
		];
	},
};

export default nextConfig;
