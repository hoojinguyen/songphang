#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: bash .agent/skills/songphang-swarm-orchestrator/scripts/init-phase-run.sh <branch-name>" >&2
	exit 1
fi

branch="$1"
case "$branch" in
	"" | *".."* | */* | main | master)
		echo "Error: invalid phase branch name '$branch'" >&2
		exit 1
		;;
esac

run_dir="docs/superpowers/runs/${branch}"
mkdir -p "$run_dir"

create_if_missing() {
	local file="$1"
	local heading="$2"
	if [ ! -e "$file" ]; then
		printf '%s\n\n' "$heading" > "$file"
		echo "Created: $file"
	else
		echo "Exists (kept): $file"
	fi
}

create_if_missing "${run_dir}/progress.md" "# ${branch} — Run Progress"
create_if_missing "${run_dir}/decisions.md" "# ${branch} — Run Decisions"
create_if_missing "${run_dir}/manual-checks.md" "# ${branch} — Manual Checks"

dirty="$(git status --short)"
if [ -n "$dirty" ]; then
	echo "Warning: working tree is not clean before starting /swarm:"
	printf '%s\n' "$dirty"
else
	echo "Working tree clean."
fi
