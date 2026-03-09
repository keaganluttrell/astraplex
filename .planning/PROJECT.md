# Astraplex

## What This Is

A real-time internal messaging platform for businesses with multiple properties. Staff and admins communicate through channels, direct messages, and ad-hoc group conversations — access controlled by channel membership, not property assignment. Built as a mobile-first PWA in Elixir/Phoenix/Ash/LiveView, this is the first end-to-end vertical designed to serve as the architectural blueprint for future domains.

## Core Value

Staff and admins can communicate in real time with messages that arrive instantly, scoped to conversations they are members of.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Admin creates and manages user accounts (no self-signup)
- [ ] Two roles: Admin (global) and Staff
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
- [ ] Admin can manage members (deactivate accounts, add/remove from channels)
- [ ] Audit log tracking admin actions
- [ ] Mobile-first responsive design (single-panel mobile, multi-panel desktop)
- [ ] PWA — installable on home screen, push notifications via service worker
- [ ] Design system / component library (research will determine which)
- [ ] Integration tests for Ash actions, policies, and PubSub behavior
- [ ] E2E tests for full user flows through LiveView (tool TBD by research)
- [ ] Static analysis and compile-time checks (Dialyzer/Credo or research alternative)
- [ ] Git hooks — pre-commit (format, compile, static analysis) and pre-push (tests)
- [ ] Test harness — standardized setup, factories, helpers
- [ ] AI usage rules (CLAUDE.md) — code conventions, architecture rules, commit conventions
- [ ] Ash AI integration (use case TBD by research)
- [ ] MCP server exposing Ash domains as tools for AI agents
- [ ] Message search (Postgres full-text or research alternative)

### Out of Scope

- Property-scoped channel visibility — properties are irrelevant to messaging; will be added as a separate domain for scheduling vertical
- Pinning/bookmarking messages — deferred to future milestone
- OAuth/SSO login — email/password sufficient for v1
- Mobile native app — PWA via LiveView
- Video/voice calls — not in scope for messaging vertical
- Message editing by users — immutable by design
- Bots/integrations — future vertical
- Unit tests — integration and E2E only

## Context

**Properties deferred:** The organization has multiple properties, but for messaging, access is purely membership-based. Admin creates channels and invites the right people. Properties will become relevant when the scheduling/staffing vertical is built — at that point, a Properties domain will be added without retrofitting messaging.

**First vertical / blueprint:** This is the first domain built on the platform. Architectural patterns established here (domain boundaries, async patterns, error handling, authorization model, testing strategy, AI tooling) will be reused as new domains are added.

**Ash domain boundaries (for messaging vertical):**
- **Accounts** — users, roles, authentication
- **Messaging** — channels, conversations, messages, threads, reactions, mentions
- **Notifications** — notification preferences, delivery (in-app, push, email)

Cross-domain communication goes through public Ash actions. Domains keep internals private.

**Key patterns to establish:**
- **Transactions:** Ash actions run in transactions by default. Multi-step operations use `manage_relationship` or `Ecto.Multi` for atomicity.
- **Fire-and-forget:** Background job queue (Oban or research alternative) for notifications, email, file processing. Durable, retryable, survives deploys.
- **Real-time broadcast:** Phoenix PubSub for ephemeral live delivery to connected users.
- **Error handling:** Ash actions are the boundary — callers get structured errors. Infrastructure failures handled by OTP supervision and job queue retries.

**Testing strategy:** No unit tests. Integration tests cover Ash actions, policies, and domain behavior. E2E tests cover full user flows through LiveView. Static analysis and compile-time type checking enforced via git hooks.

**AI tooling:** Usage rules (CLAUDE.md) encode project conventions for AI assistants. Ash AI provides AI-powered features within the platform. MCP server exposes domains for external AI tool interaction.

**Mobile-first PWA:** Responsive layout — single-panel navigation on mobile, multi-panel on desktop. Installable as PWA with service worker for push notifications. Research will evaluate touch gestures, optimistic UI, and LiveView-specific mobile patterns.

**Design system:** Component library and theming approach TBD by research. Must support mobile-first responsive patterns.

**Scale target:** 100+ users.

**Open questions for research:**
- Message search implementation (Postgres full-text vs dedicated solution)
- PubSub scaling strategy (Phoenix native vs Redis at 100+ concurrent users)
- Job queue selection (Oban vs alternatives)
- Admin tooling patterns for messaging platforms
- Design system / component library selection and available themes
- E2E testing tool (Wallaby vs Playwright vs alternatives)
- Static analysis tooling (Dialyzer + Credo vs alternatives)
- Mobile-first LiveView patterns (touch gestures, optimistic UI)
- Ash AI integration patterns for messaging
- PWA implementation with LiveView

## Constraints

- **Tech stack**: Elixir, Phoenix, Ash Framework, LiveView, Postgres — non-negotiable
- **Architecture**: Ash domains as the organizing principle — all resources, actions, and policies live within domains
- **Auth model**: Admin-created accounts only, no self-signup
- **Message integrity**: Messages are immutable once sent (admin delete is the only exception)
- **Threading**: Single-depth only — replies cannot have replies
- **Testing**: No unit tests — integration and E2E only
- **Mobile-first**: Responsive design, PWA installable
- **AI-ready**: Usage rules, Ash AI, and MCP server from the start

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Elixir/Phoenix/Ash/LiveView stack | Native real-time support, OTP for fault tolerance, Ash for authorization | — Pending |
| Immutable messages | Simplifies data model, preserves audit trail, prevents confusion | — Pending |
| Single-depth threading | Keeps conversations readable, avoids Reddit-style nesting chaos | — Pending |
| Admin-only account creation | Internal business tool, not a public platform | — Pending |
| Ash domain split (Accounts, Messaging, Notifications) | Clean boundaries, each domain owns its resources and policies | — Pending |
| Invite-only channels | Admin controls who is in each conversation | — Pending |
| No property scoping for messaging | Properties are irrelevant to message access — membership is the boundary. Properties deferred to scheduling vertical. | — Pending |
| Mobile-first PWA | Staff are often on-site with phones, not at desks. LiveView PWA avoids native app complexity. | — Pending |
| No unit tests | Integration and E2E tests provide more value for Ash domain-driven architecture | — Pending |
| AI-first development | Usage rules + Ash AI + MCP server ensures AI tools work effectively with the codebase from day one | — Pending |

---
*Last updated: 2026-03-09 after questioning*
