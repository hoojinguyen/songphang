# Remaining Roadmap Phases — Overview Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval.

This document is the entry point for the specs of everything on the roadmap after phase 1. It holds the decisions that span phases; each phase has its own spec. Plans are written from these specs after they are approved.

## 1. Intent

**What the project owner asked for (2026-11-15):** define every remaining phase of the roadmap now, as specs and plans; build later.

**Owner's answer during design:** every later phase is built like phase 1, as a phase run on the local machine. Integrations with outside services are written behind optional environment variables and stay "Not verified" until the owner supplies real credentials.

**Success looks like:** for each remaining phase the owner can start an agent run with one fixed prompt and come back to a branch that works on the local machine, with nothing left for the agent to ask.

**Assumption (advisor's):** the reason for defining everything now is to remove the advisor and the owner as a bottleneck between phases, not to freeze the product. Section 7 says how a spec is re-opened when real use contradicts it.

## 2. The specs

| Order | Phase | Spec | Branch | Size |
|---|---|---|---|---|
| 1 | 2 — Real money | `2026-11-15-phase-2-real-money-design.md` | `phase-2` | L |
| 2 | 3 — Smart entry | `2026-11-15-phase-3-smart-entry-design.md` | `phase-3` | L |
| 3 | 4 — Collaboration | `2026-11-15-phase-4-collaboration-design.md` | `phase-4` | M |
| 4 | Server step | `2026-11-15-server-step-design.md` | `server-step` | S |
| 5 | 7 — Public release | `2026-11-15-phase-7-public-release-design.md` | `phase-7` | L |
| 6 | 5 — iOS | `2026-11-15-phase-5-ios-design.md` | `phase-5` and the iOS repository | XL |
| 7 | 6 — Android | `2026-11-15-phase-6-android-design.md` | `phase-6` and the Android repository | L |

The order is the advisor's proposal, not a constraint. The real dependencies are:

- Every phase needs phase 1 merged.
- Phase 4 needs the worker of phase 3 (stage 3A) and the settlement requests of phase 2 (stage 2A) for two of its notification kinds. Section 6 says what phase 4 does when it runs without them.
- Phase 7 needs the server step.
- Phase 6 needs the API additions of phase 5 (stage 5A).

**Why the server step is not first.** The roadmap puts it right after phase 1. The owner's decision to keep building locally moves it to the moment someone else needs to use the product. It is written so that it can run at any point after phase 1; when it runs before phases 3 and 4 it simply has no worker and no bot webhook to deploy, and those phases add their own service to the Compose file (each phase spec says so).

## 3. Approaches considered

| Approach | Trade-off | Verdict |
|---|---|---|
| **A. One spec per phase, plus this overview; one plan directory per phase** | Seven documents to approve, but each can be approved, re-opened and run alone; mirrors phase 1 exactly | **Chosen** |
| B. One master spec for all phases | One approval, but any change re-opens the whole document, and an agent run must read 2,000 lines to build one phase | Rejected |
| C. Full specs only for phases 2–4; one-page outlines for the server step and phases 5–7, detailed when their turn comes | Least rework, since far phases will drift most | Rejected because the owner asked for everything to be defined now; its concern is answered by section 7 |

## 4. Run mechanics (all phases)

Identical to phase 1: `AGENTS.md` section 12, ADR-018, and sections 3.1–3.7 of `2026-11-12-phase-1-single-run-design.md`. Differences:

- Run files live in `docs/superpowers/runs/<branch>/`.
- **Task 0 of every plan is a re-baseline.** The specs were written while phase 1 stages 1B–1E were unbuilt. The agent compares the interfaces the plan names (functions, tables, routes, components) with the code on `main`, and records every difference and how the plan's tasks are adjusted in `decisions.md` before writing code. Product behavior in the spec does not change; names and file locations follow the code.
- **Gates** add, per phase, the rows of the permission matrix for the new endpoints and the acceptance scripts of **all earlier phases**, not only earlier stages.
- **`pnpm db:check-balances`** is extended by each phase that touches the money path (2C funds, 3C item splits, 4D approvals). Its meaning never weakens: every group's balances sum to 0.

## 5. Outside services: one pattern

Every phase after 1 touches a service that the agent may not call (`AGENTS.md` section 11). All of them follow the pattern phase 1 used for mail and Google:

1. **An interface in `deps`.** One small interface per capability (`Mailer`, `ReceiptReader`, `SentenceAi`, `ChatSender`, `PushSender`, `ErrorReporter`, `FileStore`).
2. **A real adapter** enabled only when its environment variables are present. Written from the provider's current documentation, which the plan links. Never exercised by the agent.
3. **A local adapter** that makes the whole feature exercisable on the local machine without the network: mail to the console, a fixture-based receipt reader, chat messages to the console, push to the console. The local adapter is selected explicitly (`*_PROVIDER=fake` or `console`), never silently in production: with `APP_ENV=production` a `fake` or `console` provider makes the API refuse to start.
4. **A capability endpoint.** `GET /api/v1/features` (public) returns one boolean per optional capability. The web app hides what is unavailable. `GET /auth/providers` stays as it is.
5. **A "Not verified" entry** in the run's `progress.md` and a section in `manual-checks.md` headed "After <service> credentials exist", with the exact steps for the owner.

No real adapter adds a library when the provider's HTTP API can be called with `fetch` in a few dozen lines. Each spec lists the libraries it does add, with license and size, for the owner's approval.

| Capability | Phase | Real adapter | Local adapter | Owner supplies |
|---|---|---|---|---|
| Mail | Server step | SMTP | Console (exists); Mailpit container for the production-like check | SMTP account |
| Receipt reading, sentence AI | 3 | Anthropic Messages API | Fixture files | API key; the 30-receipt measurement |
| Telegram | 4 | Telegram Bot API | Console sender; updates posted to the webhook with `curl` | Bot token from BotFather |
| Push | 5, 6 | APNs; FCM HTTP v1 | Console | Apple Developer account; Firebase project |
| Apple sign-in | 5 | Apple identity tokens | A locally signed token and a local key set | Apple Developer account |
| Error alerts | 7 | Webhook | Console | A webhook URL |

## 6. Survey results (roadmap step 1)

Done by the advisor on 2026-11-15 from public sources. Items marked **owner** cannot be answered by an agent and are prerequisites, not blockers: the run proceeds with the stated default.

| Question | Result | Consequence |
|---|---|---|
| VietQR format | EMVCo merchant-presented QR, NAPAS profile: merchant account template in field 38 with AID `A000000727`, the bank BIN and account number nested inside, service code `QRIBFTTA`; currency `704` in field 53; amount in 54; purpose in field 62 sub-field 08; CRC in 63 | Pure function in `core`; no service, no library. The owner scans one generated code with a real banking app before trusting it (phase 2 manual check) |
| Bank list | NAPAS publishes the member banks and their BINs | The advisor adds a static list to the repository with the phase 2 plan; the agent downloads nothing |
| MoMo, ZaloPay: open the app with a prefilled personal transfer | No documented link for person-to-person transfers was found; the documented deeplinks are for merchant payments and need a merchant account | **Stage 2E is not built.** FR-2.3 is met by its fallback: copy the phone number and the amount |
| Fund model | See phase 2 spec section 6 | A fund is a special member; no change to the balance formula |
| AI service for receipts | Not measurable by the advisor: needs 30 real receipts (**owner**) | Default: Anthropic Messages API, model set by `AI_MODEL`. The reader sits behind an interface, so the measurement can change the provider without touching the rest. Monthly ceiling is a call count, default 1,000 |
| Zalo bot in personal group chats | Sources conflict; no official statement found that a bot can join an ordinary user group | **Stage 4E is not built.** Re-survey before any later attempt |
| Telegram bot | Bot API supports group chats, commands, inline buttons and a webhook with a secret header | Stage 4C is built |
| Personal data law | Law 91/2025/QH15 and Decree 356/2025/NĐ-CP, in force since 2026-01-01, replace Decree 13/2023 | Phase 7B is written against them; the texts the advisor drafts must be read by a lawyer (**owner**) |
| Domain and trademark for "Sòng Phẳng" | Not done (**owner**) | Needed before the server step is deployed, not before it is built |

Sources are listed in section 9.

**Phases run out of the proposed order.** Phase 4 without phase 3: the worker process and queue (stage 3A, tasks named in the phase 3 plan) are built first as phase 4's task 1. Phase 4 without phase 2: the notification kinds `settlement_requested` and `settlement_confirmed` and the budget warning are left out and recorded in `decisions.md`.

## 7. Keeping far specs honest

- A spec is approved once and then frozen for its run, like phase 1.
- Between phases the owner uses the product. Feedback goes to the roadmap's waiting list. If it contradicts an approved spec of a phase that has not run, the advisor amends that spec in a dated "Amendment" section before the run, never during it.
- The specs of phases 5–7 are the most likely to be amended; the re-baseline task absorbs code drift, an amendment absorbs product drift.

## 8. Changes to standing documents

Made by the advisor after the specs are approved, together with the plans. Each phase spec lists its own; these span phases.

| Document | Change |
|---|---|
| `AGENTS.md` | Section 1 "Current phase" updated when a run starts. Section 12 generalised from "phase 1" to "the phase the plan names"; the re-baseline task added |
| `docs/04-adr.md` | ADR-019: outside services behind an interface with a local adapter and a capability endpoint. Later ADRs are listed in the phase specs |
| `docs/07-roadmap.md` | Amendment: all phases run locally as phase runs; proposed order; 2E and 4E closed by survey; search and filter moved from the waiting list into 2B |
| `docs/02-prd.md` | Open questions of section 7 marked answered, pointing to section 6 above |
| `docs/05-api-spec.md` | `GET /features` |

## 9. Sources

- [NAPAS FastFund 24/7 with VietQR](https://en.napas.com.vn/napas-fastfund-247-with-vietqr-code-service-184230612220807776.htm)
- [EMVCo Merchant-Presented QR Specification v1.1](https://mvallim.github.io/emv-qrcode/docs/EMVCo-Merchant-Presented-QR-Specification-v1-1.pdf)
- [VietQR field layout as implemented by an open-source library](https://github.com/ducnpdev/vietqr)
- [MoMo developer documentation: payment deeplinks](https://developers.momo.vn/v3/docs/payment/api/wallet/onetime/)
- [Zalo bot channel notes (third party)](https://docs.openclaw.ai/channels/zalo)
- [Vietnam's new personal data protection framework](https://chambers.com/articles/new-legal-framework-on-personal-data-protection-in-vietnam)
- [Law on Personal Data Protection and its guiding documents](https://english.luatvietnam.vn/legal-updates/the-latest-law-on-personal-data-protection-and-the-guiding-documents-892-106778-article.html)
