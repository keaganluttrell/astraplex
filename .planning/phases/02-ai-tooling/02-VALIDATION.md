---
phase: 2
slug: ai-tooling
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | test/test_helper.exs |
| **Quick run command** | `mix test test/astraplex/system/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/astraplex/system/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | AI-01 | integration | `mix test test/astraplex/system/health_test.exs` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | AI-02 | integration | `mix test test/astraplex/system/health_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/astraplex/system/health_test.exs` — integration test stubs for Health resource actions (AI-01, AI-02)
- [ ] Verify System domain compiles and tools are discoverable (compile-time check)

*Existing test infrastructure (ExUnit, test_helper.exs) covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Claude Code connects to MCP server and invokes tools | AI-01, AI-02 | Requires running Phoenix server + Claude Code client | Start server with `mix phx.server`, verify `.mcp.json` config, connect Claude Code, invoke a Health domain action |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
