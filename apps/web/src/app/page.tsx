"use client";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Button } from "../components/ui/Button";
import { MemberShape } from "../components/ui/MemberShape";
import { loginPath, useLogout, useMe } from "../lib/session";
import { t, vi } from "../messages/vi";

function GroupsSkeleton() {
	return (
		<main
			aria-busy="true"
			className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-6 px-5 py-6"
		>
			<div className="h-16 rounded-card bg-sunken" />
			<div className="my-auto h-32 rounded-card bg-sunken" />
			<div className="h-control-lg rounded-pill bg-sunken" />
		</main>
	);
}
function GroupsHeader({
	name,
	isPending,
	onLogout,
}: {
	name: string;
	isPending: boolean;
	onLogout: () => void;
}) {
	return (
		<header className="flex items-center justify-between gap-4">
			<div>
				<p className="text-sm text-muted">{t(vi.groups.greeting, { name })}</p>
				<h1 className="text-title font-black">{vi.groups.title}</h1>
			</div>
			<button
				type="button"
				aria-label={vi.common.logout}
				disabled={isPending}
				onClick={onLogout}
				className="shrink-0 rounded-pill focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink"
			>
				<MemberShape shape="circle" color="mint" size={52} name={name} />
			</button>
		</header>
	);
}
function GroupsContent({ name }: { name: string }) {
	const logout = useLogout();
	return (
		<main className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col px-5 pb-5 pt-6">
			<GroupsHeader
				name={name}
				isPending={logout.isPending}
				onLogout={() => logout.mutate()}
			/>
			<div className="flex flex-1 flex-col items-center justify-center gap-3 py-12 text-center">
				<h2 className="text-xl font-extrabold">{vi.groups.emptyTitle}</h2>
				<p className="text-muted">{vi.groups.emptyHint}</p>
				{logout.isError && (
					<div role="alert" className="mt-4 grid gap-3">
						<p>{vi.common.loadError}</p>
						<Button
							variant="surface"
							onClick={() => logout.mutate()}
							disabled={logout.isPending}
						>
							{vi.common.retry}
						</Button>
					</div>
				)}
			</div>
			<Button variant="primary" size="lg" className="w-full" disabled>
				{vi.groups.create}
			</Button>
		</main>
	);
}
export default function GroupsPage() {
	const me = useMe();
	const router = useRouter();
	useEffect(() => {
		if (me.error?.status === 401) router.replace(loginPath("/"));
	}, [me.error, router]);
	if (me.isPending || me.error?.status === 401) return <GroupsSkeleton />;
	if (me.isError)
		return (
			<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col items-center justify-center gap-4 px-5 text-center">
				<p role="alert">{vi.common.loadError}</p>
				<Button
					variant="primary"
					onClick={() => {
						void me.refetch();
					}}
					disabled={me.isFetching}
				>
					{vi.common.retry}
				</Button>
			</main>
		);
	return <GroupsContent name={me.data.name} />;
}
