---
phase: 3
slug: foundation-auth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | test/test_helper.exs |
| **Quick run command** | `mix test test/astraplex/accounts/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/astraplex/accounts/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | FOUND-01 | integration | `mix test test/astraplex/accounts/user_test.exs` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | FOUND-02 | integration | `mix test test/astraplex/accounts/user_test.exs` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | FOUND-03 | integration | `mix test test/astraplex/accounts/user_test.exs` | ❌ W0 | ⬜ pending |
| 03-01-04 | 01 | 1 | FOUND-04 | integration | `mix test test/astraplex/accounts/user_test.exs` | ❌ W0 | ⬜ pending |
| 03-01-05 | 01 | 1 | CVE-NEG | integration | `mix test test/astraplex/accounts/user_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | FOUND-04 | integration | `mix test test/astraplex_web/live/auth_live_test.exs` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | FOUND-05 | e2e | `mix test test/e2e/auth_test.exs --include e2e` | ❌ W0 | ⬜ pending |
| 03-02-03 | 02 | 2 | FOUND-06 | integration + e2e | `mix test test/astraplex_web/live/auth_live_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/astraplex/accounts/user_test.exs` — stubs for FOUND-01, FOUND-02, FOUND-03, FOUND-04
- [ ] `test/astraplex/accounts/user_authorization_test.exs` — negative auth tests (CVE-2025-48043)
- [ ] `test/astraplex_web/live/auth_live_test.exs` — sign-in/sign-out LiveView flows
- [ ] `test/astraplex_web/live/admin/user_list_live_test.exs` — admin user management UI
- [ ] `test/e2e/auth_test.exs` — session persistence, full login/logout flow
- [ ] Smokestack factory for User in `test/support/factory.ex`
- [ ] Auth test helpers (register_and_log_in_user) in `test/support/conn_case.ex`
- [ ] `config :bcrypt_elixir, log_rounds: 1` in `config/test.exs`
- [ ] Token signing secret in `config/test.exs` and `config/dev.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Session persists across browser refresh | FOUND-05 | Requires real browser session state | E2E test covers this with headless browser |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
