# Research Summary: Astraplex

**Domain:** Real-time internal messaging platform for multi-property businesses
**Researched:** 2026-03-09
**Overall confidence:** HIGH

## Executive Summary

Astraplex is a real-time internal messaging platform built on Elixir/Phoenix/Ash/LiveView with PostgreSQL. The Elixir ecosystem is exceptionally well-suited for this domain -- Phoenix's built-in PubSub, Presence (CRDT-based), and LiveView streams map directly to the core requirements of real-time message delivery, online/offline tracking, and efficient message list rendering. The Ash Framework provides declarative domain modeling with built-in authorization policies, PubSub notifiers, and attribute-based multitenancy, which together solve the property-scoping challenge that is Astraplex's core differentiator.

The stack requires no external dependencies beyond PostgreSQL. Oban (PostgreSQL-backed) handles background jobs. Phoenix PubSub (PG2 adapter) handles real-time fan-out. Phoenix Presence handles online/offline tracking. Full-text search uses PostgreSQL's tsvector/tsquery. This "all-Postgres" approach dramatically simplifies operations -- no Redis, no Elasticsearch, no external message broker. At the target scale of 100+ concurrent users, this architecture is more than sufficient.

The primary risk areas are: (1) Ash policy authorization logic, which uses non-obvious union/intersection semantics and has had a real CVE (CVE-2025-48043), requiring careful policy design and negative authorization testing from day one; (2) LiveView memory management, which demands the use of streams over assigns for message lists; and (3) multi-tenant property scoping, which must use attribute-based multitenancy rather than schema-based to support cross-property channels and multi-property staff.

The rich text story requires TipTap (ProseMirror-based editor) integrated via a LiveView JS hook. This is the most custom work in the stack -- TipTap provides the editor and mention extension, but the LiveView integration for mention autocomplete (querying users via pushEvent) is bespoke. Store messages as TipTap JSON in a JSONB column, with a plain-text extraction for full-text search indexing.

## Key Findings

**Stack:** Elixir 1.17 / Phoenix 1.8.5 / Ash 3.19 / LiveView 1.1.26 / PostgreSQL 15+ / Oban 2.20 -- zero external services beyond Postgres.

**Architecture:** Four Ash domains (Accounts, Properties, Messaging, Notifications) with attribute-based multitenancy on property_id. Polymorphic messages table serves channels, DMs, and group conversations. LiveView streams for message rendering. Phoenix PubSub for real-time broadcast. Oban for async notifications.

**Critical pitfall:** Ash policy authorization uses filter-based reads that silently return wrong data rather than raising errors. Combined with a known CVE in bypass policies, this demands negative authorization tests ("staff cannot see other property's data") from the first resource definition.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Foundation (Auth, Properties, Database)** - Must come first because everything depends on user accounts, property assignments, and the multitenancy model. Ash policies and attribute-based multitenancy must be correct from the start.
   - Addresses: User accounts, roles, property model, admin seed
   - Avoids: Multi-tenant data leakage (Pitfall 3), policy authorization errors (Pitfall 1)

2. **Core Messaging (Channels, Messages, PubSub)** - Property-scoped channels only (no cross-property yet). Establishes the message schema, PubSub topic structure, LiveView streams, and keyset pagination.
   - Addresses: Channels, messages, real-time delivery, basic message list UI
   - Avoids: Memory bloat from assigns (Pitfall 2), offset pagination (Pitfall 2 in STACK.md), missing FK indexes

3. **Conversations & Threading** - DMs and group conversations extend the messaging foundation. Single-depth reply threading adds the parent_id reference.
   - Addresses: DMs, group messages, threading, polymorphic message display
   - Avoids: Scope creep into nested threading

4. **Presence, Typing, Unread Tracking** - Real-time polish layer. Presence via Phoenix Presence CRDT. Typing via raw PubSub broadcasts (not Presence). Unread counts via watermark pattern on membership.
   - Addresses: Online/offline, typing indicators, unread badges, read receipts
   - Avoids: Unread count bottleneck (Pitfall 5), typing via Presence (Pitfall 8 in STACK.md), PubSub fan-out overload (Pitfall 4)

5. **Rich Messaging** - TipTap integration, @mentions, reactions, file uploads. This phase has the most custom JS work (TipTap hook, mention autocomplete, scroll management).
   - Addresses: Rich text, mentions, reactions, file uploads, message search
   - Avoids: TipTap JSON without plain-text extraction

6. **Notifications & Admin** - In-app notification feed, email (Swoosh + Oban), browser push (WebPushElixir + Oban), mute preferences. Admin UI for user/channel management, audit log.
   - Addresses: All notification channels, admin tooling, audit trail, cross-property channels
   - Avoids: Notification storms (Pitfall 10 in STACK.md), synchronous notification delivery

**Phase ordering rationale:**
- Auth and properties are the foundation everything builds on -- no messaging without users
- Channels before conversations because they are simpler and validate PubSub/stream patterns without polymorphic complexity
- Presence/unread after messaging because they layer on top of working message delivery
- Rich messaging after conversations because TipTap/mentions/uploads are polish on an already-functional message system
- Notifications last because they require all message types, mentions, and preferences to exist
- Cross-property channels deferred to the final phase because the authorization model must be mature

**Research flags for phases:**
- Phase 1: Likely needs deeper research into Ash multitenancy configuration specifics
- Phase 2: Standard patterns, well-documented in Phoenix community
- Phase 4: Unread watermark + materialized count pattern needs careful schema design upfront
- Phase 5: TipTap + LiveView hook integration is the least documented area -- may need prototyping
- Phase 6: WebPushElixir is a smaller library (MEDIUM confidence) -- verify it meets needs during implementation

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All packages verified on hex.pm with current versions; Ash 3.x is mature and actively maintained |
| Features | HIGH | Feature landscape well-understood from Slack/Teams/Discord comparisons and PROJECT.md requirements |
| Architecture | HIGH | Phoenix PubSub + LiveView streams + Ash domains is a well-documented pattern; attribute-based multitenancy is the right fit |
| Pitfalls | HIGH | CVE-verified, community-sourced, and pattern-matched against known Elixir/Phoenix failure modes |
| TipTap integration | MEDIUM | Community examples exist but mention autocomplete via LiveView hook is custom work with limited documentation |
| WebPushElixir | MEDIUM | Small library, recently updated, but fewer production references than Swoosh or Oban |

## Gaps to Address

- **TipTap + LiveView hook prototyping:** The mention autocomplete flow (pushEvent from JS hook to LiveView, receive user suggestions, render popup) should be prototyped early in Phase 5 to validate the approach.
- **Ash multitenancy with global? true:** The cross-property channel pattern using `global? true` on multitenancy needs validation against Ash 3.19 documentation during Phase 1 setup.
- **Message table partitioning:** Whether to partition by `inserted_at` from day one or defer. At 100 users / 50 messages per day, the table reaches ~1.8M rows/year. Partitioning is recommended but may not be critical for v1.
- **UUIDv7 support in Ecto/Ash:** Using time-sortable UUIDs (UUIDv7) for message IDs simplifies pagination and partitioning. Verify Ash/Ecto support for UUIDv7 generation.
- **Oban job transactional integrity with Ash:** Verify that AshOban enqueues jobs within the same transaction as the Ash action, ensuring atomicity.
