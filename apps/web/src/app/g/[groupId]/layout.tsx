"use client";
import { useParams } from "next/navigation";
import type { ReactNode } from "react";
import { useGroupEvents } from "../../../lib/use-group-events";
export default function GroupLayout({ children }: { children: ReactNode }) {
	const { groupId } = useParams<{ groupId: string }>();
	useGroupEvents(groupId);
	return children;
}
