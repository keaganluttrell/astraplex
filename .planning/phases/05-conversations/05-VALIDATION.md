---
phase: 5
slug: conversations
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | test/test_helper.exs |
| **Quick run command** | `mix test test/astraplex/messaging/conversation_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/astraplex/messaging/ -x`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | DM-01 | integration | `mix test test/astraplex/messaging/conversation_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | DM-02 | integration | `mix test test/astraplex/messaging/conversation_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-03 | 01 | 1 | DM-03 | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-04 | 01 | 1 | GRP-01 | integration | `mix test test/astraplex/messaging/conversation_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-05 | 01 | 1 | GRP-02 | integration | `mix test test/astraplex/messaging/conversation_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-06 | 01 | 1 | GRP-03 | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-07 | 01 | 1 | GRP-04 | N/A | N/A — descoped | N/A | ⬜ descoped |
| 05-01-08 | 01 | 1 | CROSS | integration | `mix test test/astraplex/messaging/conversation_test.exs` | ❌ W0 | ⬜ pending |
| 05-01-09 | 01 | 1 | CROSS | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | CROSS | integration | `mix test test/astraplex/messaging/message_test.exs` | Extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/astraplex/messaging/conversation_test.exs` — stubs for DM-01, DM-02, GRP-01, GRP-02, uniqueness
- [ ] `test/astraplex/messaging/conversation_authorization_test.exs` — stubs for DM-03, GRP-03, admin restrictions
- [ ] `test/support/factory.ex` — add Conversation and ConversationMembership factories
- [ ] Extend `test/astraplex/messaging/message_test.exs` — covers send_conversation_message action
- [ ] Extend `test/astraplex/messaging/message_authorization_test.exs` — covers conversation message policy

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sidebar real-time updates via PubSub | DM-02, GRP-02 | Requires two browser sessions | Open 2 browsers as different users, send DM, verify sidebar updates in recipient's browser |
| Lazy creation UX (no empty conversations) | DM-01 | UI state management before persist | Start new conversation, verify nothing appears in sidebar until first message sent |
| Scroll behavior (start at top, snap to bottom) | CROSS | Visual behavior | Open conversation with few messages — verify they start at top. Send enough to fill viewport — verify pinned to bottom |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
