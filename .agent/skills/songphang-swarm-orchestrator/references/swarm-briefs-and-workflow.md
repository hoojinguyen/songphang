# Swarm Brief & Orchestrator Templates

## 1. Mandatory Worker Brief Contract

Copy and fill this block into every `swarm` `add` `brief` (workers start with empty conversation history):

```markdown
You own **<role>** on `<BRANCH>` inside your `<share|inherit>` workspace.

### Read First
- `AGENTS.md` (especially §6 no automated tests, §7–§12)
- `apps/ios/AGENTS.md` (required for any iOS worker)
- `.agents/skills/execute-task/SKILL.md` (phase-run mode) and `.agents/skills/security-review/SKILL.md`
- Spec & Stage Plan: `<SPEC_PATH>`, `<PLAN_STAGE_PATH>`

### Scope & Write Boundary
- **Allowed paths:** `<exact directories/files>`
- **Do NOT touch:** `<other layers, hot files owned elsewhere, docs/03..07, docs/tech-debt.md, run files if coordinator-owned>`
- **Assigned tasks:** `<task IDs>`

### Environment & Verification Rules
- `share` worktrees have no `.env`: pass `DATABASE_URL="<disposable_db_url>"` directly to `pnpm --filter @songphang/db exec tsx src/...`; run isolated API/worker exercises on a non-`:4000` port (e.g. `:4111`) with an isolated `STORAGE_DIR` outside the repo.
- No automated tests (`*.test.*`, `*.spec.*`). Zero emoji anywhere.
- Integer-only VND money; `pnpm contract:check` must pass with 0 breaking changes.
- iOS Simulator build command:
  `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`
- If UI changes are visible, capture Simulator/Web screenshots in your `<appData>/brain/<conversation-id>/` directory and include `Screenshot: <abs_path> | <summary <= 10 words>` on its own line.

### Done Looks Like
1. One scoped commit per task (`type(scope): short description`) after local checks pass. Never push or touch `main`.
2. Post `@coordinator` with: commit hashes, files changed, verbatim command/exercise outputs, security checks, decisions (`problem/options/choice/reason`), and any `Not verified` items.
```

---

## 2. `swarm_pane` Overview `plan.json` Skeleton

Write to `<appData>/brain/<coordinator_conversation_id>/.system_generated/swarm/plan.json` once initial workers are added:

```json
{
  "goal": {
    "title": "Deliver Sòng Phẳng Wave 5.5B",
    "line": "Lock API/DB contract first, then ship Web, iOS, and parity gates."
  },
  "tasks": {
    "api-db": "Migrations, core logic, OpenAPI, and API gate",
    "web": "Next.js v2 flows and vi.ts copy",
    "ios": "SongPhangKit features, SwiftUI, and string parity",
    "verifier": "Integrated stage gates and parity checks"
  },
  "threads": [
    {
      "id": "t-foundation",
      "title": "API, DB & Contract Lock",
      "goal": "Additive schema, endpoints, and OpenAPI verified on disposable DB.",
      "tasks": ["api-db"]
    },
    {
      "id": "t-clients",
      "title": "Web & iOS Parity",
      "goal": "Both clients match locked contract and vi.ts strings.",
      "tasks": ["web", "ios"]
    },
    {
      "id": "t-gates",
      "title": "Integrated Gates & Handoff",
      "goal": "Merged branch passes build, balances, security, and parity.",
      "tasks": ["verifier"]
    }
  ]
}
```

---

## 3. Read-Only `run_workflow` Pre-Handoff Audit Script

Use with `run_workflow` on the integrated `<BRANCH>` (`workspace: "inherit"`, read-only audits) before writing the final handoff:

```python
import json

phase("Parallel read-only verification")

audit_schema = {
    "type": "object",
    "properties": {
        "status": {"type": "string", "enum": ["pass", "findings"]},
        "findings": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"},
                    "severity": {"type": "string", "enum": ["must_fix", "should_fix"]},
                    "issue": {"type": "string"},
                    "fix": {"type": "string"},
                },
                "required": ["location", "severity", "issue", "fix"],
            },
        },
    },
    "required": ["status", "findings"],
}

base = args.get("base_ref", "main")
angles = [
    (
        "Security & Auth Audit",
        "inherit",
        f"Inspect `git diff {base}..HEAD` using `.agents/skills/security-review/SKILL.md`. "
        "Verify Zod validation, 404 for group outsiders, no secrets/logs, no dangerouslySetInnerHTML, "
        "and no test files (`*.test.*` / `*.spec.*`). Do NOT modify files.",
    ),
    (
        "Money & Architecture Audit",
        "inherit",
        f"Inspect `git diff {base}..HEAD` against `AGENTS.md` §7 and `apps/ios/AGENTS.md` §3/§5. "
        "Verify integer-only VND money (no floats/division on Money), server-owned calculations, "
        "and strict SongPhangKit module boundaries. Do NOT modify files.",
    ),
    (
        "Web/iOS Parity & Hygiene Audit",
        "flash",
        f"Inspect `git diff {base}..HEAD` and run `./apps/ios/Scripts/check-strings.sh` if needed. "
        "Check character-for-character Vietnamese copy parity, dark-mode token contrast, and zero emoji. "
        "Do NOT modify files.",
    ),
]

results = await parallel(
    angles,
    lambda item: agent(
        prompt=item[2],
        schema=audit_schema,
        role=item[0],
        workspace="inherit",
        model=item[1],
    ),
)

must_fixes = [
    {"angle": angles[i][0], **f}
    for i, r in enumerate(results)
    for f in r["findings"]
    if f["severity"] == "must_fix"
]
log(f"Audit complete: {len(must_fixes)} must_fix finding(s)")
print(json.dumps({"results": results, "must_fixes": must_fixes}, ensure_ascii=False, indent=2))
```
