import { NextResponse } from "next/server";
import { z } from "zod";

export const dynamic = "force-dynamic";

const appleAppIdSchema = z
	.string()
	.trim()
	.max(255)
	.regex(/^[A-Z0-9]{10}\.[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/);

export function GET() {
	const parsed = appleAppIdSchema.safeParse(process.env.APPLE_APP_ID);
	if (!parsed.success) {
		return new NextResponse(null, {
			status: 404,
			headers: { "Cache-Control": "no-store" },
		});
	}

	return NextResponse.json(
		{
			applinks: {
				details: [
					{
						appIDs: [parsed.data],
						components: [{ "/": "/join/*" }],
					},
				],
			},
		},
		{
			status: 200,
			headers: { "Cache-Control": "public, max-age=3600" },
		},
	);
}
