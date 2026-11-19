import { type NextRequest, NextResponse, type ProxyConfig } from "next/server";
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

if (!apiOrigin.success) {
	throw new Error("API_ORIGIN must be a valid HTTP(S) origin");
}

export const config: ProxyConfig = {
	matcher: ["/notifications/unsubscribe"],
};

export function proxy(request: NextRequest) {
	if (request.method === "POST") {
		return NextResponse.rewrite(
			new URL(
				`/api/v1/notifications/unsubscribe${request.nextUrl.search}`,
				apiOrigin.data,
			),
		);
	}
	return NextResponse.next();
}
