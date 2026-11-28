# Phase 5.6 — Stage D: Data, Checks and Handoff

> Paths are relative to `apps/ios/SongPhangKit/Sources/` unless they start with `apps/` or `docs/`.

### Task 5.6.D.1: Fake scenarios and launch flags

Closes: F4-32; makes the roadmap overview's section 6 screens reachable.

**Files:**
- Modify: `PreviewSupport/Fakes/{FakeWorld,FakeWorld+Payments,FakeWorld+FundBudget,FakeWorld+Ledger,FakeWorld+ChatLinks,FakeWorld+CyclesAndGuest,FakeWorld+Stats}.swift`, `PreviewSupport/Fakes/{FakeRepositories,FakeSettlementRequestsRepository,FakeGuestLinksRepository}.swift`, `PreviewSupport/Samples/*`, `PreviewSupport/Scenarios/*`
- Modify: `AppShell/RootView.swift` (flag parsing), `AppShell/SessionModel.swift` (scripted features at launch), `AppShell/Debug/DebugPanel.swift` (list the new flags)

**Interfaces:**
- Produces flags (names may be adjusted; record the final names):
  - `--with-payment-details`: the current user and the payee have bank details, so the VietQR pay sheet opens.
  - `--with-pending-request`: a settlement request awaits the current user's confirmation.
  - `--with-fund`: a shared fund with contributions and a balance.
  - `--with-pending-approval`: a large expense awaits approval.
  - `--feature-telegram`: server features with Telegram enabled.
  - `--guest-token`: the scripted token opens a guest page with content (fix the current broken-link-only behaviour if that is what the re-baseline finds).
  - `--upgrade-required`: the upgrade-required screen.
  - `--push-prompt`: the push-permission pre-prompt.
- Produces: in scripted mode, server features load at launch (not only on foreground), so the receipt camera and Telegram entries appear without relaunching.
- Produces: the stats fake's total equals the sum of its category amounts (literals, chosen to match an existing captured response shape).
- Constraint: every fake returns literals (`apps/ios/AGENTS.md` §5); no arithmetic on `Money` in fakes. The balances, transfers and QR payloads in new scenarios are literals consistent with each other.

- [ ] **Step 1: Read the current fakes** and record, per flag, which literal data is missing and why the screen was unreachable.
- [ ] **Step 2: Add the scenarios and flags**; list them in the debug panel.
- [ ] **Step 3: Scripted features at launch.**
- [ ] **Step 4: Stats fake consistency.**
- [ ] **Step 5: Exercise** every flag; capture each screen into `screens/stage-d/scenarios/`. Try widget and share-extension screens from the Simulator home screen and Photos share sheet; record what is not possible under "Not verified".
- [ ] **Step 6: Gate and commit.** `git commit -m "feat(ios): add scripted scenarios for unreachable screens"`

---

### Task 5.6.D.2: Checks, findings and handoff

Closes: F2-64, F2-63 and F4-53 (verification), F3-59, F3-60, F3-61, F4-07, F4-08, F4-56; verifies every other finding of the phase.

**Files:**
- Modify: `docs/superpowers/runs/phase-5-6/{progress,decisions,manual-checks,copy-changes}.md`
- Create: `docs/superpowers/runs/phase-5-6/screens/final/*`

- [ ] **Step 1: Screenshot matrix** (spec section 13.1): every `Route` case and every sheet, light, dark, largest accessibility text size, iPhone SE (3rd generation), plus `--scenario-large` for the group screens, plus the Stage D scenarios. Name files `<screen>-<variant>.png`.
- [ ] **Step 2: Reduce Motion pass.** With Reduce Motion on, walk every moment of spec section 6.3 and the three money moments; record per moment what happens.
- [ ] **Step 3: VoiceOver pass** (Simulator, Accessibility Inspector) on the group screen, Settle, the expense form, the member picker and the account setting; record what is read.
- [ ] **Step 4: iPhone SE pass.** Compare with the "before" captures; no answer moved further down; record the starting point for 5.7.
- [ ] **Step 5: Profiling after.** Repeat the Task 0 profile; record body-update counts before and after; investigate any increase over 20% and fix or record it. Use `drawingGroup` only where the profile shows a gain.
- [ ] **Step 6: Findings record.** In `progress.md`, a table of every finding ID and defect of spec section 16 with what was done, the commit, and the evidence (screenshot or observation). Anything not closed is listed under "Not verified" or "Gate not passed" with the reason.
- [ ] **Step 7: Owner guide.** Write `manual-checks.md` in Vietnamese from spec section 15 (13 numbered checks on a physical iPhone), adding what Stage D could not verify in the Simulator (haptics, ringer switch, music interruption, device performance).
- [ ] **Step 8: Final gate.** iOS gate; `check-strings.sh` (allowed keys equal the rows of `copy-changes.md`); `pnpm check`; `git status` clean apart from the commit; delete any simulator created for the run.
- [ ] **Step 9: Commit.** `git commit -m "docs(ios): record phase 5.6 checks, findings and manual check guide"`

## After the run (advisor)

- Review per `AGENTS.md` §12; update `docs/superpowers/research/2026-11-28-ui-ux-v3-review/findings.md` statuses for every ID of spec section 16 and the seven defects.
- Update `docs/06-ux-ui/user-flows.md` with the v3 interaction rules of spec sections 4–11 (spec section 14).
- Owner checks by hand with `manual-checks.md` and merges `phase-5-6`.
