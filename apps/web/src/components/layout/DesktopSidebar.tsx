"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useGroups } from "../../lib/groups";
import { formatSignedAmount } from "../../lib/money";
import { useUnreadNotificationCount } from "../../lib/notifications";
import { useMe } from "../../lib/session";
import { type ThemeMode, useThemeMode } from "../../lib/theme";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";

export function DesktopSidebar() {
	const pathname = usePathname();
	const me = useMe();
	const groupsQuery = useGroups("active");
	const unread = useUnreadNotificationCount();
	const count = unread.data?.count ?? 0;
	const [theme, setTheme] = useThemeMode();

	const navItems = [
		{ href: "/", label: vi.tabs.overview, icon: "home" as const },
		{ href: "/groups", label: vi.tabs.groups, icon: "grid" as const },
		{
			href: "/ledger",
			label: vi.ledger.title,
			icon: "search" as const,
		},
		{
			href: "/notifications",
			label: vi.tabs.notifications,
			icon: "bell" as const,
			badge: count,
		},
		{ href: "/account", label: vi.tabs.account, icon: "person" as const },
	];

	const activeGroups = groupsQuery.data ?? [];

	return (
		<aside
			aria-label={vi.desktop.navigation}
			className="sticky top-0 flex h-dvh w-[260px] shrink-0 flex-col justify-between border-r border-sunken bg-bg p-5"
		>
			<div className="flex min-h-0 flex-1 flex-col gap-6">
				{/* Brand Header */}
				<div className="flex items-center justify-between">
					<Link href="/" className="text-xl font-black tracking-tight text-ink">
						{vi.common.appName}
					</Link>
					{me.data && (
						<Link
							href="/account"
							aria-label={me.data.name}
							className="rounded-full ring-2 ring-transparent transition-all hover:ring-ink"
						>
							<MemberShape
								shape="circle"
								color="mint"
								size={32}
								name={me.data.name}
							/>
						</Link>
					)}
				</div>

				{/* Primary Nav Links */}
				<nav className="grid gap-1">
					{navItems.map((item) => {
						const active =
							item.href === "/"
								? pathname === "/"
								: pathname.startsWith(item.href);

						return (
							<Link
								key={item.href}
								href={item.href}
								aria-current={active ? "page" : undefined}
								className={`flex items-center justify-between rounded-[16px] px-3.5 py-2.5 text-sm font-bold transition-colors ${
									active
										? "bg-ink text-on-ink"
										: "text-muted hover:bg-surface hover:text-ink"
								}`}
							>
								<div className="flex items-center gap-3">
									<Icon name={item.icon} size={20} />
									<span>{item.label}</span>
								</div>
								{item.badge !== undefined && item.badge > 0 && (
									<span className="rounded-full bg-coral px-1.5 py-0.5 text-[10px] font-black text-on-accent">
										{item.badge > 9 ? "9+" : item.badge}
									</span>
								)}
							</Link>
						);
					})}
				</nav>

				{/* Active Groups Quick Switcher */}
				<div className="flex min-h-0 flex-1 flex-col gap-2">
					<div className="flex items-center justify-between px-1">
						<span className="text-xs font-bold uppercase tracking-wider text-muted">
							{vi.desktop.activeGroups}
						</span>
						<Link
							href="/groups/new"
							aria-label={vi.groups.create}
							className="text-muted hover:text-ink"
						>
							<Icon name="plus" size={16} />
						</Link>
					</div>
					<div className="min-h-0 flex-1 overflow-y-auto pr-1">
						<div className="grid gap-1">
							{activeGroups.map((g) => {
								const active = pathname.startsWith(`/g/${g.id}`);
								const tone =
									g.myBalance > 0
										? "text-credit"
										: g.myBalance < 0
											? "text-debt"
											: "text-muted";

								return (
									<Link
										key={g.id}
										href={`/g/${g.id}`}
										className={`flex items-center justify-between rounded-[14px] px-3 py-2 text-xs font-bold transition-colors ${
											active
												? "bg-surface text-ink shadow-sm"
												: "text-muted hover:bg-surface/50 hover:text-ink"
										}`}
									>
										<div className="flex items-center gap-2 truncate">
											<div className="flex -space-x-1 shrink-0">
												{g.previewMembers.slice(0, 2).map((m) => (
													<MemberShape key={m.id} {...m} size={16} />
												))}
											</div>
											<span className="truncate">{g.name}</span>
										</div>
										<div className="flex items-center gap-1.5 shrink-0 pl-1">
											{Boolean(
												g.pendingActionCount && g.pendingActionCount > 0,
											) && <span className="size-2 rounded-full bg-coral" />}
											<span className={`tabular-nums ${tone}`}>
												{formatSignedAmount(g.myBalance)}
											</span>
										</div>
									</Link>
								);
							})}
						</div>
					</div>
				</div>
			</div>

			{/* Footer CTA & Theme Toggle */}
			<div className="mt-4 grid gap-3 border-t border-sunken pt-4">
				<Link
					href="/groups/new"
					className="flex h-11 items-center justify-center gap-2 rounded-pill bg-ink text-sm font-bold text-on-ink transition-opacity hover:opacity-90"
				>
					<Icon name="plus" size={18} />
					<span>{vi.groups.create}</span>
				</Link>

				{/* Theme Toggle */}
				<div className="flex rounded-pill bg-sunken p-1">
					{(["light", "system", "dark"] as ThemeMode[]).map((mode) => (
						<button
							key={mode}
							type="button"
							onClick={() => setTheme(mode)}
							aria-label={
								mode === "light"
									? vi.appearance.light
									: mode === "dark"
										? vi.appearance.dark
										: vi.appearance.system
							}
							className={`flex flex-1 items-center justify-center rounded-pill py-1.5 text-xs font-bold transition-all ${
								theme === mode
									? "bg-surface text-ink shadow-sm"
									: "text-muted hover:text-ink"
							}`}
						>
							<Icon
								name={
									mode === "light"
										? "sun"
										: mode === "dark"
											? "moon"
											: "circle-half"
								}
								size={16}
							/>
						</button>
					))}
				</div>
			</div>
		</aside>
	);
}
