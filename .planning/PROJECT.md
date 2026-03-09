# Astraplex

## What This Is

A real-time internal messaging platform for multi-property businesses. Staff and admins communicate through channels, direct messages, and ad-hoc group conversations — scoped by property and role. Built in Elixir/Phoenix/Ash/LiveView as the first end-to-end vertical, designed to serve as the architectural blueprint for future domains.

## Core Value

Staff and admins can communicate in real time across properties with messages that arrive instantly and are scoped to what each user has access to.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Admin creates and manages user accounts (no self-signup)
- [ ] Two roles: Admin (global) and Staff (property-scoped)
- [ ] Staff can be assigned to multiple properties
- [ ] Admin creates invite-only channels and controls membership
- [ ] Any user can create DMs (1:1) and ad-hoc group messages (2+ people)
- [ ] Users only see conversations they are members of
- [ ] Messages support rich text, mentions, reactions, and file uploads (images inline)
- [ ] Single-depth reply threading — replies attach to parent message, no nesting
- [ ] Messages are immutable (no edit/delete by users; admin can delete)
- [ ] Full real-time: live message delivery, online/offline presence, typing indicators
- [ ] Unread badges/counters per channel and conversation
- [ ] Read receipts (seen-by indicators on messages)
- [ ] Mute channels/conversations (silence notifications, stays visible)
- [ ] In-app notifications, browser push notifications, and email notifications
- [ ] New channel members see full message history
- [ ] Admin can manage members (add/remove staff from properties, deactivate accounts)
- [ ] Audit log tracking admin actions

### Out of Scope

- Pinning/bookmarking messages — deferred to future milestone
- OAuth/SSO login — email/password sufficient for v1
- Mobile native app — web-first via LiveView
- Video/voice calls — not in scope for messaging vertical
- Message editing by users — immutable by design
- Bots/integrations — future vertical

## Context

**Multi-property model:** The organization manages multiple properties (sites). Admin operates globally across all properties. Staff are assigned to one or more properties and their access is scoped accordingly. Channel scoping across properties (property-local vs cross-property vs both) is an open question for research to inform.

**First vertical / blueprint:** This is the first domain built on the platform. Architectural patterns established here (domain boundaries, async patterns, error handling, authorization model) will be reused as new domains are added.

**Ash domain boundaries:**
- **Accounts** — users, roles, authentication, property assignments
- **Messaging** — channels, conversations, messages, threads, reactions, mentions
- **Notifications** — notification preferences, delivery (in-app, push, email)
- **Properties** — property management, membership

Cross-domain communication goes through public Ash actions. Domains keep internals private.

**Key patterns to establish:**
- **Transactions:** Ash actions run in transactions by default. Multi-step operations use `manage_relationship` or `Ecto.Multi` for atomicity (e.g., create channel + add creator as first member).
- **Fire-and-forget:** Background job queue (Oban or research alternative) for notifications, email, file processing. Durable, retryable, survives deploys.
- **Real-time broadcast:** Phoenix PubSub for ephemeral live delivery to connected users.
- **Error handling:** Ash actions are the boundary — callers get structured errors. Infrastructure failures handled by OTP supervision and job queue retries.

**Scale target:** 100+ users across multiple properties.

**Open questions for research:**
- Channel scoping across properties (best practice for multi-property orgs)
- Message search implementation (Postgres full-text vs dedicated solution)
- PubSub scaling strategy (Phoenix native vs Redis at 100+ concurrent users)
- Job queue selection (Oban vs alternatives)
- Admin tooling patterns for messaging platforms

## Constraints

- **Tech stack**: Elixir, Phoenix, Ash Framework, LiveView, Postgres — non-negotiable
- **Architecture**: Ash domains as the organizing principle — all resources, actions, and policies live within domains
- **Auth model**: Admin-created accounts only, no self-signup
- **Message integrity**: Messages are immutable once sent (admin delete is the only exception)
- **Threading**: Single-depth only — replies cannot have replies

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Elixir/Phoenix/Ash/LiveView stack | Native real-time support, OTP for fault tolerance, Ash for authorization | — Pending |
| Immutable messages | Simplifies data model, preserves audit trail, prevents confusion | — Pending |
| Single-depth threading | Keeps conversations readable, avoids Reddit-style nesting chaos | — Pending |
| Admin-only account creation | Internal business tool, not a public platform | — Pending |
| Ash domain split (Accounts, Messaging, Notifications, Properties) | Clean boundaries, each domain owns its resources and policies | — Pending |
| Invite-only channels | Admin controls information flow across properties | — Pending |

---
*Last updated: 2026-03-09 after initialization*
