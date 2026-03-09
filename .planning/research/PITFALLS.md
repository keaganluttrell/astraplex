# Pitfalls Research

**Domain:** Real-time internal messaging platform (Elixir/Phoenix/Ash/LiveView + Postgres)
**Researched:** 2026-03-09
**Confidence:** HIGH (stack-specific, verified across official docs, CVEs, and community sources)

## Critical Pitfalls

### Pitfall 1: Ash Policy Authorization Logic Produces Silent Data Leakage

**What goes wrong:**
Ash policies use a union/intersection model that is unintuitive. Multiple `authorize_if` checks within a single `policy` block act as OR (any one passes = authorized). Developers expecting AND semantics put all checks in one block and accidentally over-authorize. Conversely, action types not explicitly covered by any policy are silently forbidden, causing mysterious 403s. A real CVE (CVE-2025-48043, CVSS 8.6, patched in Ash 3.6.2) demonstrated that bypass policies with runtime-dependent conditions could generate permissive query filters, returning unauthorized data on read operations.

**Why it happens:**
Ash policies are declarative and composable, but their boolean logic differs from what most developers expect from role-based guards. The union-within-policy vs. intersection-across-policies distinction is subtle. Filter-based authorization (the default for reads) silently narrows results rather than raising errors, so over-permissive policies return too much data without any visible error.

**How to avoid:**
- Use separate `policy` blocks when conditions must ALL be true (intersection). Use multiple `authorize_if` in one block only for OR logic.
- Always end policy blocks with explicit `authorize_if always()` or `forbid_if always()` as a deliberate default -- never leave the fallthrough ambiguous.
- Cover ALL action types in policies. If you split policies by `:read`, `:create`, `:update`, `:destroy`, add explicit pass-through policies for types you do not restrict.
- Pin Ash >= 3.6.2 to avoid the bypass policy CVE.
- Write authorization integration tests that assert: (a) users CAN access what they should, AND (b) users CANNOT access what they should not. Test the negative case explicitly -- filter authorization makes the positive case pass silently even when broken.

**Warning signs:**
- Users see data from other properties or channels they are not members of.
- Tests only verify "admin can do X" without verifying "staff cannot do Y."
- No `forbid_if always()` or `authorize_if always()` at the end of policy blocks.

**Phase to address:**
Foundation phase (domain setup). Policies must be correct from the first resource definition. Retrofitting authorization is extremely expensive because filter-based reads silently return wrong data rather than erroring.

---

### Pitfall 2: LiveView Process Memory Bloat from Chat History in Assigns

**What goes wrong:**
Each LiveView connection is a server-side process. Storing chat message history in socket assigns means every connected user holds a copy of all loaded messages in server memory. With 100 users each viewing a channel with 500 messages at ~200 bytes each, that is 10MB just for message data -- and it grows with every loaded page of history. Worse, when a message arrives via PubSub broadcast, naive implementations re-assign the entire messages list, triggering a full re-render diff of every message.

**Why it happens:**
The natural pattern in LiveView is `assign(socket, :messages, messages)`. It works perfectly for small datasets. Developers build the feature with 10 test messages, ship it, and discover memory issues only under real usage with real message volumes.

**How to avoid:**
- Use LiveView streams (`stream/3`, `stream_insert/4`) from day one for all message lists. Streams detach data from the server process and let the client hold the DOM state. The server only tracks stream metadata, not the actual message data.
- Set `stream` limits (e.g., `:limit` option) to cap how many messages the client DOM retains, typically 3x the page size.
- When new messages arrive via PubSub, use `stream_insert(socket, :messages, message, at: -1)` to append a single item rather than re-fetching and re-assigning the full list.
- Store pagination cursors (oldest loaded message ID) in a simple assign, not the messages themselves.

**Warning signs:**
- `socket.assigns` contains a list of messages or any growing collection.
- BEAM observer shows LiveView processes using >1MB each.
- Page loads slow down as channels accumulate messages.

**Phase to address:**
Core messaging phase. Streams must be the rendering strategy from the first message list implementation. Migrating from assigns to streams later requires rewriting templates and all message-handling event callbacks.

---

### Pitfall 3: Multi-Tenant Data Leakage Through Missing Property Scoping

**What goes wrong:**
In a multi-property messaging platform, the most dangerous bug is a user in Property A seeing messages, channels, or presence data from Property B. This can happen at multiple layers: database queries missing a `property_id` filter, PubSub topic names not scoped by property, or Ash actions called without tenant context. Because this is an internal business tool, the consequences are not just privacy violations but operational trust failures.

**Why it happens:**
Astraplex's model is NOT classic multi-tenancy (separate schemas per tenant). Staff can belong to multiple properties, and admins operate globally. This means you cannot use Postgres schema-based isolation. You must use attribute-based scoping (`property_id` on every property-scoped resource), and every query path must enforce it. It is easy to forget scoping in one query, one PubSub subscription, or one admin action.

**How to avoid:**
- Use Ash's attribute-based multitenancy (`multitenancy type: :attribute, attribute: :property_id`) on every property-scoped resource. Ash will crash if a tenant is not provided, which is exactly what you want -- fail closed.
- Scope PubSub topics by property: `"property:#{property_id}:channel:#{channel_id}"` not just `"channel:#{channel_id}"`.
- For DMs and ad-hoc groups (which are not property-scoped), use conversation membership checks in policies rather than property scoping.
- Admin actions that cross properties must explicitly bypass tenant scoping and should be wrapped in audit-logged Ash actions with separate policies.
- Write cross-property isolation tests: create data in Property A, authenticate as Property B staff, assert zero results.

**Warning signs:**
- PubSub topic strings that do not contain a property identifier.
- Ash resources with `property_id` but no multitenancy declaration.
- No integration tests that cross property boundaries.

**Phase to address:**
Foundation phase (resource and domain design). The scoping model must be baked into the schema and resource definitions. Adding it later means auditing every query, every PubSub subscription, and every template.

---

### Pitfall 4: PubSub Fan-Out Overload on Busy Channels

**What goes wrong:**
When a message is sent to a channel with 50 members, Phoenix PubSub broadcasts to all 50 subscriber processes. Each process receives the message, diffs its LiveView, and pushes an update over WebSocket. The broadcast itself is fast, but each subscriber process must handle the message. If the payload is large (rich text, file metadata, mention data) or if broadcasts are frequent (active typing indicators at 1/second per user), subscriber processes can build up message queue backlogs, causing latency spikes and eventual timeouts.

**Why it happens:**
PubSub is designed for ephemeral fan-out, not for high-frequency streaming. Developers broadcast the full message struct (with preloaded associations) instead of minimal payloads. Typing indicators naively broadcast on every keystroke. The system works fine with 5 users but degrades at 50 concurrent users in one channel.

**How to avoid:**
- Broadcast minimal payloads (message ID + essential display fields). Let each LiveView process fetch additional data only if needed.
- Throttle typing indicators: broadcast at most once per 2-3 seconds per user. Use a client-side debounce and a server-side `Process.send_after` dedup.
- Use separate PubSub topics for different event types: `"channel:#{id}:messages"` vs `"channel:#{id}:typing"` vs `"channel:#{id}:presence"`. This lets processes subscribe selectively.
- For presence, use Phoenix.Presence which handles diff-based broadcasting rather than full state broadcasts.

**Warning signs:**
- PubSub broadcast payloads larger than 1KB.
- Typing indicators broadcasting on every `phx-keyup` event.
- All real-time events on a single PubSub topic per channel.
- Process message queue lengths growing (visible in BEAM observer).

**Phase to address:**
Real-time features phase. Must be designed correctly when implementing live delivery, typing indicators, and presence. The PubSub topic structure should be decided during architecture, even if not all event types are implemented immediately.

---

### Pitfall 5: Unread Count Calculation Becomes a Performance Bottleneck

**What goes wrong:**
Calculating unread counts by running `SELECT COUNT(*) FROM messages WHERE channel_id = ? AND created_at > (SELECT last_read_at FROM memberships WHERE ...)` on every page load and every incoming message is expensive. With 100 users each in 20 channels, the sidebar alone generates 2,000 count queries. As message tables grow, these queries slow down even with indexes, especially when combined with the read receipt tracking requirement.

**Why it happens:**
Counting unread messages is conceptually simple. Developers implement it as a derived count and it works in development. The query is fast with 1,000 messages. At 100,000 messages across channels, the aggregation becomes the dominant query on every page load.

**How to avoid:**
- Store unread counts as a materialized value on the `membership` (or `channel_member`) record: `unread_count` integer column.
- Increment `unread_count` for all members (except the sender) when a message is created. Decrement (reset to 0) when a user reads the channel.
- Use a single query to load all unread counts for a user's sidebar: `SELECT channel_id, unread_count FROM memberships WHERE user_id = ?`.
- Accept that counts may be slightly stale (eventual consistency) -- this is acceptable for badge numbers.
- Update counts in PubSub broadcasts so the sidebar updates in real time without re-querying.

**Warning signs:**
- Sidebar load time increases as message volume grows.
- `EXPLAIN ANALYZE` shows sequential scans on the messages table for count queries.
- Database CPU spikes correlate with user logins (sidebar rendering).

**Phase to address:**
Core messaging phase. The membership schema must include `unread_count` and `last_read_at` from the beginning. Retrofitting materialized counts requires a data migration and recount of all existing message/membership pairs.

---

### Pitfall 6: Postgres Message Table Without Partitioning or Archival Strategy

**What goes wrong:**
A single `messages` table accumulates rows indefinitely. At 100 users sending 50 messages/day, the table grows by ~5,000 rows/day, reaching 1.8M rows/year. Indexes on `(channel_id, inserted_at)` grow proportionally. VACUUM operations become expensive. Queries for recent messages remain fast, but admin operations (bulk delete, analytics, exports) slow to a crawl. Index bloat increases memory usage.

**Why it happens:**
The messages table is rarely the bottleneck in the first months. Growth is linear and gradual. By the time it becomes a problem, the table is large and partitioning an existing table requires a migration that is complex and risky.

**How to avoid:**
- Use range partitioning by `inserted_at` (monthly or quarterly) from the start. Postgres native partitioning (`PARTITION BY RANGE`) is transparent to Ecto queries.
- Design the primary key as `(id, inserted_at)` to support partition pruning. Note: unique constraints must include the partition key, so UUIDs alone cannot be the primary key on a partitioned table.
- If using UUIDs for message IDs, use UUIDv7 (time-sortable) so the ID itself encodes insertion order, reducing the need for separate timestamp indexes.
- Plan an archival strategy: detach old partitions after N months, move to cold storage or separate analytics database.

**Warning signs:**
- Messages table is a single unpartitioned table.
- Using UUIDv4 for message IDs (random, not time-sortable).
- No discussion of data lifecycle or archival in the schema design.

**Phase to address:**
Foundation phase (schema design). Partitioning must be set up in the initial migration. Adding partitioning to an existing table with data requires creating a new partitioned table, migrating data, and swapping -- a high-risk operation.

---

### Pitfall 7: LiveView Infinite Scroll for Chat Has Subtle UX and State Bugs

**What goes wrong:**
Chat UIs need bidirectional scroll: load older messages when scrolling up, receive new messages at the bottom. LiveView streams handle this, but the implementation has known edge cases: (a) `phx-viewport-top` triggers during initial render if the container is not yet full, causing unwanted history loads; (b) page refresh mid-scroll loses scroll position; (c) new messages arriving while the user is reading history push them down unexpectedly; (d) stream limits that are too aggressive discard messages the user just read.

**Why it happens:**
Chat scroll behavior is inherently stateful (scroll position, loaded range, active reading state) but LiveView streams are designed for append/prepend operations without explicit scroll state management. The gap between "stream works" and "chat scroll feels right" requires significant JavaScript hook work.

**How to avoid:**
- Use a JS hook that manages scroll position: pin to bottom when the user is at the bottom, preserve position when loading history, and show a "new messages" indicator when messages arrive while scrolled up.
- Guard `phx-viewport-top` with a flag that only enables after the initial render completes.
- Set stream limits to at least 3x the page size so users have enough buffer to scroll without hitting the limit.
- Test with slow connections: PubSub messages arriving during a history load can interleave and cause visual jumps.

**Warning signs:**
- No JavaScript hook for scroll management -- relying purely on LiveView's default behavior.
- Chat jumps to the bottom when new messages arrive while the user is reading history.
- Loading spinner appears on initial page load due to premature viewport trigger.

**Phase to address:**
Core messaging phase (UI implementation). This is a UX-critical feature that needs dedicated attention. Plan for a JS hook from the start rather than trying to fix scroll behavior after the fact.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Storing full message list in assigns instead of streams | Simpler initial implementation | Memory bloat per connection, full re-render on each update | Never -- streams are not harder, just different |
| Computing unread counts on the fly | No extra schema columns | O(n) queries on every page load, scales poorly | Prototype only, replace before any real usage |
| Single PubSub topic per channel for all event types | Less topic management code | Cannot selectively subscribe, typing floods message handlers | Only acceptable if typing indicators are deferred |
| Skipping Ash multitenancy declarations and filtering manually | Avoid learning Ash multitenancy API | Inconsistent scoping, easy to miss a query, no crash-on-missing-tenant safety net | Never -- Ash multitenancy is the safety net |
| No message table partitioning | Simpler initial migration | Painful to add later, index bloat, slow admin operations | Acceptable if total messages will stay under 500K for the foreseeable future |
| Synchronous notification delivery in the request path | Simpler implementation, no job queue | Request latency includes email/push delivery time, failures block the sender | Never -- use Oban from the start |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Oban job queue | Enqueuing jobs outside of the database transaction, causing jobs to fire even if the transaction rolls back | Use `Oban.insert/2` inside the Ecto transaction or Ash action so the job is committed atomically with the data change |
| Phoenix PubSub | Broadcasting before the database transaction commits -- subscribers query the DB and get stale data | Broadcast in an `after_action` hook or after `Repo.transaction` returns `:ok` |
| Phoenix Presence | Tracking presence on the LiveView mount without handling reconnections -- presence sticks after disconnection | Use `Presence.track` in `mount/3` with proper cleanup; Phoenix Presence handles node-level cleanup via CRDTs but process-level cleanup depends on the LiveView process terminating |
| Browser push notifications (Web Push) | Sending pushes for every message including ones the user is actively viewing in their open tab | Check presence/online status before queuing push notifications; only push to users who are offline or viewing a different channel |
| File uploads (images inline) | Storing uploads in the local filesystem | Use external storage (S3-compatible) from the start; LiveView has built-in external upload support with presigned URLs |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| N+1 queries loading channel members for sidebar | Sidebar load time grows linearly with channel count | Preload members in a single query, cache channel member lists | >20 channels per user |
| Full message struct in PubSub broadcasts | High memory per broadcast, slow serialization | Broadcast only message ID + display fields, let receivers load associations if needed | >30 concurrent users in one channel |
| Counting unread via `SELECT COUNT(*)` | Sidebar queries dominate DB load | Materialized `unread_count` column on membership | >10K total messages |
| No database index on `(channel_id, inserted_at)` | Message loading queries scan full table | Add composite index on the messages table; if partitioned, the partition key handles most pruning | >50K messages |
| Presence diff broadcast storms | Network saturation, client-side jitter | Batch presence updates, debounce on 2-second intervals | >50 concurrent users across channels |
| Loading all channels + counts on every navigation | Repeated sidebar queries on LiveView patch | Use a persistent `live_session` assign or a dedicated sidebar LiveView component that subscribes to count updates via PubSub | Any scale, but wasteful |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| PubSub topics not scoped by property | Users receive broadcasts from channels in other properties, leaking message content | Include `property_id` in all PubSub topic strings |
| Ash policies only test positive authorization | Filter-based reads silently return unauthorized data rather than raising errors | Write negative authorization tests: "Staff B cannot see Property A channels" |
| Relying on client-side channel filtering | UI hides channels but API/LiveView events still deliver data | All filtering must happen server-side in Ash policies and PubSub subscriptions |
| No rate limiting on message sends | A compromised or misbehaving client floods a channel | Add server-side rate limiting (e.g., max 10 messages/minute per user per channel) via Ash action validation or a token bucket |
| Admin delete without audit log | No record of which admin deleted which message, undermining the immutability guarantee | Log all admin destructive actions in an append-only audit table, integrated into the Ash action |
| File upload without type/size validation | Users upload executable files or multi-GB files | Validate MIME type and file size in LiveView upload config; use `accept` and `max_file_size` options |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No "new messages" indicator when scrolled up | User misses new messages while reading history | Show a floating badge "N new messages" with a click-to-scroll-down action |
| Typing indicator shows for stale events | "User is typing..." persists after the user stopped or left | Expire typing indicators after 3 seconds of no update; clear on message send |
| Read receipts update on every scroll event | Performance drain, feels surveillance-like | Update read position only when the user pauses on a message for >1 second, or on explicit scroll-to-bottom |
| Notifications for muted channels | Users receive push/email for channels they muted | Check mute status before any notification delivery, including in-app badges |
| No offline indicator for message send failures | User thinks message sent but it was lost due to disconnection | Show a "not sent" indicator with retry option on reconnection; LiveView handles reconnection but the UX needs explicit handling |

## "Looks Done But Isn't" Checklist

- [ ] **Authorization:** Verified that staff cannot see channels/messages from properties they are not assigned to -- not just that they CAN see their own
- [ ] **Real-time delivery:** Verified that messages arrive for all members, not just the sender's own LiveView -- requires multi-browser/multi-session testing
- [ ] **Unread counts:** Verified counts update correctly across: new message, reading a channel, muting a channel, being removed from a channel
- [ ] **Presence:** Verified that closing a browser tab (not just navigating away) correctly removes the user from presence tracking
- [ ] **File uploads:** Verified upload works with slow connections, large files show progress, and failed uploads show errors -- not just happy-path testing
- [ ] **Typing indicators:** Verified indicators clear when user sends the message, switches channels, or disconnects -- not just when they stop typing
- [ ] **Notifications:** Verified that in-app, push, and email notifications all respect mute settings and online status -- not just that notifications send
- [ ] **Message ordering:** Verified that messages from multiple users posting simultaneously appear in consistent order for all viewers -- PubSub delivery order is not guaranteed to match insertion order
- [ ] **Admin actions:** Verified that admin message deletion removes the message from all connected users' streams in real time, not just from the database

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Ash policy data leakage | HIGH | Audit all policies, add negative tests, review logs for unauthorized access, potentially notify affected users |
| Memory bloat from assigns | MEDIUM | Rewrite message rendering to use streams, update all event handlers, test scroll behavior end-to-end |
| Missing property scoping | HIGH | Add multitenancy declarations to all resources, migrate data to ensure `property_id` is set, audit PubSub topics |
| Unpartitioned message table | HIGH | Create new partitioned table, migrate data in batches (potentially millions of rows), swap table names, update constraints |
| Unread count computed on the fly | MEDIUM | Add `unread_count` column, backfill with a migration script that counts existing messages, update all message-create and channel-read actions |
| Single PubSub topic per channel | LOW | Rename topics by appending event type suffix, update all subscribers -- can be done incrementally |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Ash policy logic errors | Foundation (domain/resource setup) | Negative authorization tests pass for every resource and action |
| LiveView memory bloat | Core messaging (first message list) | BEAM observer shows <500KB per LiveView process with 100+ messages loaded |
| Multi-tenant data leakage | Foundation (schema design) | Cross-property isolation integration tests pass |
| PubSub fan-out overload | Real-time features | Load test with 50 concurrent users in one channel shows <100ms broadcast latency |
| Unread count bottleneck | Core messaging (membership schema) | `unread_count` column exists on membership table, no COUNT queries in sidebar |
| Message table partitioning | Foundation (initial migration) | Messages table uses `PARTITION BY RANGE (inserted_at)` |
| Chat scroll UX bugs | Core messaging (UI) | Manual QA: scroll up to load history, receive new message, verify no scroll jump |
| Oban job transactional integrity | Notifications phase | Jobs are enqueued inside Ash actions or Ecto transactions; test rollback does not fire jobs |
| Presence cleanup on disconnect | Real-time features | Close browser tab, verify presence clears within 10 seconds |

## Sources

- [Ash Policies Gotchas - Jake Trent](https://jaketrent.com/post/ash-policies-gotchas/)
- [Ash Policies Official Documentation (v3.16)](https://hexdocs.pm/ash/policies.html)
- [Ash Authorization CVE-2025-48043 (GHSA-7r7f-9xpj-jmr7)](https://github.com/ash-project/ash/security/advisories/GHSA-7r7f-9xpj-jmr7)
- [Building a Chat App with LiveView Streams - Fly.io Phoenix Files](https://fly.io/phoenix-files/building-a-chat-app-with-liveview-streams/)
- [LiveView Assigns: Three Common Pitfalls - AppSignal](https://blog.appsignal.com/2022/06/28/liveview-assigns-three-common-pitfalls-and-their-solutions.html)
- [LiveView Memory Usage Discussion - Elixir Forum](https://elixirforum.com/t/liveview-process-memory-usage-seems-high-am-i-doing-something-wrong/27036)
- [Distributed Phoenix: Deployment and Scaling - AppSignal](https://blog.appsignal.com/2024/12/10/distributed-phoenix-deployment-and-scaling.html)
- [PubSub Broadcast Performance - Elixir Forum](https://elixirforum.com/t/pubsub-broadcast-performance-and-best-practice/60175)
- [Multitenancy in Elixir - Curiosum](https://www.curiosum.com/blog/multitenancy-in-elixir)
- [Multitenancy in Ash Framework - Alembic](https://alembic.com.au/blog/multitenancy-in-ash-framework)
- [Phoenix Presence Documentation (v1.8)](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
- [Efficient Bidirectional Infinite Scroll in Phoenix LiveView - DEV Community](https://dev.to/christianalexander/efficient-bidirectional-infinite-scroll-in-phoenix-liveview-3epd)
- [Failing Big with Elixir and LiveView - Pentacent Post-Mortem](https://pentacent.com/blog/failing-big-elixir-liveview/)
- [Oban GitHub Repository](https://github.com/oban-bg/oban)
- [Phoenix LiveView Streams - ElixirCasts](https://elixircasts.io/phoenix-liveview-streams)

---
*Pitfalls research for: Astraplex real-time internal messaging platform*
*Researched: 2026-03-09*
