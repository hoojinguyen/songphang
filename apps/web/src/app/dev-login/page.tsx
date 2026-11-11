"use client";
import {
	DevLoginRequest,
	DevUsersResponse,
	type UserDto,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { Button } from "../../components/ui/Button";
import { MemberShape } from "../../components/ui/MemberShape";
import { type ApiError, apiFetch, apiSend } from "../../lib/api";
import { devShapeFor } from "../../lib/dev-shapes";
import { safeNext } from "../../lib/session";
import { t, vi } from "../../messages/vi";

function LoginSkeleton() {
	return (
		<div aria-busy="true" className="grid grid-cols-2 gap-4">
			{[0, 1, 2, 3].map((index) => (
				<div key={index} className="h-40 rounded-card bg-sunken" />
			))}
		</div>
	);
}
function useLogin() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const queryClient = useQueryClient();

	return useMutation<void, ApiError, string>({
		mutationFn: (userId) =>
			apiSend("/dev/login", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify(DevLoginRequest.parse({ userId })),
			}),
		onSuccess: async () => {
			await queryClient.cancelQueries();
			queryClient.clear();
			router.replace(safeNext(searchParams.get("next")));
		},
	});
}
function LoginChoices({
	users,
	isPending,
	onSelect,
}: {
	users: UserDto[];
	isPending: boolean;
	onSelect: (userId: string) => void;
}) {
	return (
		<div className="grid grid-cols-2 gap-4">
			{users.map((user, index) => (
				<button
					key={user.id}
					type="button"
					aria-label={t(vi.devLogin.enterAs, { name: user.name })}
					disabled={isPending}
					onClick={() => onSelect(user.id)}
					className="flex min-h-40 flex-col items-center justify-center gap-3 rounded-card bg-surface p-4 font-bold focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink disabled:opacity-60"
				>
					<MemberShape {...devShapeFor(index)} size={84} name={user.name} />
					<span>{user.name}</span>
				</button>
			))}
		</div>
	);
}
function LoginOptions() {
	const users = useQuery({
		queryKey: ["dev-users"],
		queryFn: () => apiFetch("/dev/users", DevUsersResponse),
		retry: false,
	});
	const login = useLogin();
	if (users.isPending) return <LoginSkeleton />;
	if (users.isError)
		return (
			<div className="grid justify-items-center gap-4 py-10 text-center">
				<p role="alert">{vi.common.loadError}</p>
				<Button
					variant="primary"
					onClick={() => {
						void users.refetch();
					}}
					disabled={users.isFetching}
				>
					{vi.common.retry}
				</Button>
			</div>
		);
	return (
		<div className="grid gap-4">
			<LoginChoices
				users={users.data.users}
				isPending={login.isPending}
				onSelect={login.mutate}
			/>
			{login.isError && (
				<p role="alert" className="text-center text-muted">
					{vi.common.loadError}
				</p>
			)}
		</div>
	);
}
export default function DevLoginPage() {
	return (
		<main className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col gap-6 px-5 py-8">
			<header className="grid gap-3">
				<h1 className="text-title font-black">{vi.devLogin.title}</h1>
				<p className="text-muted">{vi.devLogin.hint}</p>
			</header>
			<Suspense fallback={<LoginSkeleton />}>
				<LoginOptions />
			</Suspense>
		</main>
	);
}
