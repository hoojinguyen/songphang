"use client";
import { ChangePasswordCard } from "../../components/account/ChangePasswordCard";
import { DeleteAccountCard } from "../../components/account/DeleteAccountCard";
import { NotificationSettingsCard } from "../../components/account/NotificationSettingsCard";
import { Button } from "../../components/ui/Button";
import { LoadError } from "../../components/ui/LoadError";
import { MemberShape } from "../../components/ui/MemberShape";
import { ScreenHeader } from "../../components/ui/ScreenHeader";
import { useLogout, useMe } from "../../lib/session";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
export default function AccountPage() {
	const me = useMe();
	const logout = useLogout();
	useSessionGuard(me.error ?? logout.error);
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-5 px-5 py-6">
			<ScreenHeader
				title={vi.account.title}
				backHref="/"
				backLabel={vi.common.back}
			/>
			{me.isPending || me.error?.status === 401 ? (
				<div aria-busy="true" className="h-80 rounded-card bg-sunken" />
			) : me.isError ? (
				<LoadError
					onRetry={() => {
						void me.refetch();
					}}
					isRetrying={me.isFetching}
				/>
			) : (
				<>
					<div className="flex items-center gap-3 rounded-[30px] bg-surface p-5">
						<MemberShape
							shape="circle"
							color="mint"
							size={52}
							name={me.data.name}
						/>
						<div className="min-w-0">
							<p className="break-words text-base font-extrabold">
								{me.data.name}
							</p>
							<p className="break-all text-[13px] text-muted">
								{me.data.email}
							</p>
						</div>
					</div>
					{me.data.hasPassword && <ChangePasswordCard />}
					<NotificationSettingsCard />
					<Button
						variant="surface"
						size="lg"
						onClick={() => logout.mutate()}
						disabled={logout.isPending}
					>
						{vi.common.logout}
					</Button>
					{logout.isError && <p role="alert">{vi.common.saveError}</p>}
					<DeleteAccountCard email={me.data.email} />
				</>
			)}
		</main>
	);
}
