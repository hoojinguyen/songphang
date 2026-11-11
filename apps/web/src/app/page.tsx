import { Button } from "../components/ui/Button";
import { Card } from "../components/ui/Card";
import { MemberShape } from "../components/ui/MemberShape";
import { vi } from "../messages/vi";

const MEMBERS = [
	{ name: vi.showcase.members.minh, shape: "circle", color: "mint" },
	{ name: vi.showcase.members.lan, shape: "diamond", color: "sky" },
	{ name: vi.showcase.members.hung, shape: "squircle", color: "coral" },
	{ name: vi.showcase.members.thu, shape: "leaf", color: "lilac" },
] as const;

function ShapeExamples() {
	return (
		<div className="grid gap-6">
			{[24, 52, 84].map((size) => (
				<div key={size} className="grid grid-cols-4 gap-2">
					{MEMBERS.map((member) => (
						<div key={member.name} className="flex flex-col items-center gap-2">
							<MemberShape {...member} size={size} />
							<span className="text-sm text-muted">{member.name}</span>
						</div>
					))}
				</div>
			))}
		</div>
	);
}

function ButtonExamples() {
	return (
		<div className="flex flex-wrap items-center gap-3">
			{(["primary", "accent", "surface"] as const).map((variant) =>
				(["md", "lg"] as const).map((size) => (
					<Button key={`${variant}-${size}`} variant={variant} size={size}>
						{vi.common.retry}
					</Button>
				)),
			)}
			<Button variant="primary" disabled>
				{vi.groups.create}
			</Button>
		</div>
	);
}

function CardExamples() {
	return (
		<div className="grid gap-3">
			{(["surface", "accent", "sunken"] as const).map((tone) => (
				<Card key={tone} tone={tone}>
					<h2 className="font-extrabold">{vi.groups.emptyTitle}</h2>
					<p className="mt-2 text-muted">{vi.groups.emptyHint}</p>
				</Card>
			))}
		</div>
	);
}

export default function ShowcasePage() {
	return (
		<main className="mx-auto flex max-w-2xl flex-col gap-8 px-5 py-8">
			<h1 className="text-title font-black">{vi.common.appName}</h1>
			<ShapeExamples />
			<ButtonExamples />
			<CardExamples />
		</main>
	);
}
