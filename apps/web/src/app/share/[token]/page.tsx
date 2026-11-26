import type { Metadata } from "next";
import { GuestGroupPage } from "../../../components/guest/GuestGroupPage";

export const metadata: Metadata = {
	robots: { index: false, follow: false },
};

export default async function SharePage({
	params,
}: {
	params: Promise<{ token: string }>;
}) {
	const { token } = await params;
	return <GuestGroupPage token={token} />;
}
