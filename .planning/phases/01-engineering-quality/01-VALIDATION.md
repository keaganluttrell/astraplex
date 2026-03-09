---
phase: 1
slug: engineering-quality
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (ships with Elixir) + PhoenixTestPlaywright v0.13.0 |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test --exclude e2e` |
| **Full suite command** | `mix test --include e2e` |
| **Estimated runtime** | ~15 seconds (unit/integration), ~45 seconds (with E2E) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --exclude e2e`
- **After every plan wave:** Run `mix test --exclude e2e && mix credo --strict`
- **Before `/gsd:verify-work`:** `mix test --include e2e && mix credo --strict && mix dialyzer && mix format --check-formatted`
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | QUAL-01 | smoke | `mix test test/astraplex/ --exclude e2e` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | QUAL-02 | smoke | `mix test test/e2e/ --include e2e` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | QUAL-03 | manual | `mix credo --strict && mix dialyzer` | ❌ W0 | ⬜ pending |
| 01-04-01 | 01 | 1 | QUAL-06 | smoke | `mix test test/support/factory_test.exs` | ❌ W0 | ⬜ pending |
| 01-05-01 | 03 | 2 | QUAL-04 | manual-only | Manual: commit badly formatted code, verify rejection | N/A | ⬜ pending |
| 01-06-01 | 03 | 2 | QUAL-05 | manual-only | Manual: push with failing test, verify rejection | N/A | ⬜ pending |
| 01-07-01 | 03 | 2 | QUAL-07 | manual-only | Check file exists and contains required sections | N/A | ⬜ pending |
| 01-08-01 | 02 | 1 | QUAL-08 | smoke | `mix test test/astraplex_web/components/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/factory.ex` — Smokestack factory module (empty, ready for resources)
- [ ] `test/support/data_case.ex` — DataCase with Ash test config and factory import
- [ ] `test/support/conn_case.ex` — ConnCase with auth helper stubs
- [ ] `test/support/e2e_case.ex` — E2E case module wrapping PhoenixTestPlaywright
- [ ] `test/e2e/smoke_test.exs` — Minimal smoke test proving E2E works
- [ ] `.credo.exs` — Credo strict configuration
- [ ] Framework install: `mix deps.get && npm --prefix assets i -D playwright && npx --prefix assets playwright install chromium --with-deps`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pre-commit hook rejects bad code | QUAL-04 | Requires git commit interaction | 1. Stage badly formatted `.ex` file 2. Run `git commit` 3. Verify hook rejects with format error |
| Pre-push hook rejects failing tests | QUAL-05 | Requires git push interaction | 1. Add a failing test 2. Run `git push` 3. Verify hook rejects with test failure |
| CLAUDE.md exists with conventions | QUAL-07 | File content review | 1. Verify file exists 2. Check for code conventions, architecture rules, commit conventions sections |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
