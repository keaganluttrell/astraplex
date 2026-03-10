---
phase: 4
slug: channels
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/astraplex/messaging/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/astraplex/messaging/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | CHAN-01 | integration | `mix test test/astraplex/messaging/channel_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | CHAN-01 | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-03 | 01 | 1 | CHAN-02 | integration | `mix test test/astraplex/messaging/membership_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-04 | 01 | 1 | CHAN-02 | integration | `mix test test/astraplex/messaging/membership_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-05 | 01 | 1 | CHAN-03 | integration | `mix test test/astraplex/messaging/membership_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-06 | 01 | 1 | CHAN-03 | integration | `mix test test/astraplex/messaging/membership_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-07 | 01 | 1 | CHAN-04 | integration | `mix test test/astraplex/messaging/channel_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-08 | 01 | 1 | CHAN-04 | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-09 | 01 | 1 | CHAN-05 | integration | `mix test test/astraplex/messaging/message_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-10 | 01 | 1 | CHAN-05 | integration | `mix test test/astraplex/messaging/message_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-11 | 01 | 1 | CHAN-06 | integration | `mix test test/astraplex/messaging/channel_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-12 | 01 | 1 | CHAN-06 | integration | `mix test test/astraplex/messaging/message_test.exs` | ❌ W0 | ⬜ pending |
| 04-01-13 | 01 | 1 | CHAN-06 | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/astraplex/messaging/channel_test.exs` — stubs for CHAN-01, CHAN-04, CHAN-06
- [ ] `test/astraplex/messaging/channel_authorization_test.exs` — negative auth for CHAN-01, CHAN-04, CHAN-06
- [ ] `test/astraplex/messaging/membership_test.exs` — stubs for CHAN-02, CHAN-03
- [ ] `test/astraplex/messaging/membership_authorization_test.exs` — negative auth for CHAN-02, CHAN-03
- [ ] `test/astraplex/messaging/message_test.exs` — stubs for CHAN-05, CHAN-06 message blocking
- [ ] `test/astraplex/messaging/message_authorization_test.exs` — negative auth for CHAN-05
- [ ] Factory additions in `test/support/factory.ex` — Channel, Membership, Message factories

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-time channel message appearance | CHAN-05 | PubSub broadcast requires two browser sessions | Open two browsers as channel members, send message in one, verify it appears in the other |
| Sidebar channel list updates on membership change | CHAN-04 | Requires visual verification of LiveView update | Add user to channel, verify sidebar updates without page refresh |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
