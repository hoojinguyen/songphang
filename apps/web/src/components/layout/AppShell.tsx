"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { useUnreadNotificationCount } from "../../lib/notifications";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { SnackbarProvider } from "../ui/Snackbar";
import { DesktopInspectorProvider } from "./DesktopInspectorContext";
import { DesktopSidebar } from "./DesktopSidebar";
import { GroupInspector } from "./GroupInspector";

const AUTH_PATHS = new Set([
	"/login",
	"/register",
	"/forgot-password",
	"/reset-password",
	"/verify-email",
	"/dev-login",
]);

function isAuthPath(pathname: string): boolean {
	if (AUTH_PATHS.has(pathname)) return true;
	if (pathname.startsWith("/join/")) return true;
	if (pathname.startsWith("/link/")) return true;
	if (pathname.startsWith("/notifications/unsubscribe")) return true;
	return false;
}

function MobileTabBar() {
	const pathname = usePathname();
	const unread = useUnreadNotificationCount();
	const count = unread.data?.count ?? 0;

	const tabs = [
		{ href: "/", label: vi.tabs.overview, icon: "home" as const },
		{ href: "/groups", label: vi.tabs.groups, icon: "grid" as const },
		{
			href: "/notifications",
			label: vi.tabs.notifications,
			icon: "bell" as const,
			badge: count,
		},
		{ href: "/account", label: vi.tabs.account, icon: "person" as const },
	];

	return (
		<nav
			aria-label={vi.desktop.navigation}
			className="fixed bottom-0 left-0 right-0 z-10 flex h-[72px] items-center border-t border-sunken bg-bg pb-safe lg:hidden"
		>
			{tabs.map((tab) => {
				const active =
					tab.href === "/" ? pathname === "/" : pathname.startsWith(tab.href);
				return (
					<Link
						key={tab.href}
						href={tab.href}
						aria-label={
							tab.badge
								? t(vi.notifications.bellUnreadLabel, {
										count: String(tab.badge),
									})
								: tab.label
						}
						aria-current={active ? "page" : undefined}
						className={`relative flex flex-1 flex-col items-center justify-center gap-1 py-2 text-[10px] font-bold ${active ? "text-ink" : "text-muted"}`}
					>
						<Icon name={tab.icon} size={24} />
						<span>{tab.label}</span>
						{tab.badge !== undefined && tab.badge > 0 && (
							<span
								aria-hidden="true"
								className="absolute left-1/2 top-1.5 -translate-x-1/2 translate-x-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-coral px-1 text-[10px] font-extrabold text-on-accent"
							>
								{tab.badge > 9 ? "9+" : String(tab.badge)}
							</span>
						)}
					</Link>
				);
			})}
		</nav>
	);
}

export function AppShell({ children }: { children: ReactNode }) {
	const pathname = usePathname();
	const isAuth = isAuthPath(pathname);

	if (isAuth) {
		return <>{children}</>;
	}

	const groupMatch = pathname.match(/^\/g\/([^/]+)/);
	const rawGroupId = groupMatch?.[1];
	const currentGroupId = rawGroupId ? decodeURIComponent(rawGroupId) : null;
	const isGroupRoute = pathname.startsWith("/g/");

	return (
		<SnackbarProvider>
			<DesktopInspectorProvider currentGroupId={currentGroupId}>
				<div className="flex min-h-dvh w-full justify-center bg-bg">
					{/* Sticky Left Rail: DesktopSidebar (>= 1024px) */}
					<div className="hidden lg:block shrink-0">
						<DesktopSidebar />
					</div>

					{/* Center Workspace (up to 760px on desktop) */}
					<div
						className={`min-w-0 flex-1 max-w-[760px] w-full ${!isGroupRoute ? "pb-[88px] lg:pb-0" : ""}`}
					>
						{children}
					</div>

					{/* Sticky Right Rail: GroupInspector (>= 1280px on /g/[groupId]*) */}
					{currentGroupId && (
						<div className="hidden xl:block shrink-0">
							<GroupInspector groupId={currentGroupId} />
						</div>
					)}

					{/* Fixed Bottom 4-Tab Bar (< 1024px) on top-level views */}
					{!isGroupRoute && <MobileTabBar />}
				</div>
			</DesktopInspectorProvider>
		</SnackbarProvider>
	);
}
