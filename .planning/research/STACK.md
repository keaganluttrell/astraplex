# Technology Stack

**Project:** Astraplex - Real-Time Internal Messaging Platform
**Researched:** 2026-03-09

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Elixir | ~> 1.17 | Language | Native concurrency, BEAM VM fault tolerance, pattern matching for message routing | HIGH |
| Phoenix | ~> 1.8.5 | Web framework | Real-time primitives (Channels, PubSub, Presence) built in; LiveView for server-rendered UI | HIGH |
| Phoenix LiveView | ~> 1.1.26 | UI layer | Server-rendered reactive UI eliminates JS SPA complexity; native upload support; ideal for internal tools | HIGH |
| Ash Framework | ~> 3.19 | Application framework | Declarative resources/actions/policies map directly to domain model; built-in authorization, pagination, PubSub notifiers | HIGH |
| AshPhoenix | ~> 2.3.20 | Ash + Phoenix integration | Form helpers, LiveView integration, error handling for Ash actions in Phoenix | HIGH |
| AshPostgres | ~> 2.6.32 | Data layer | PostgreSQL data layer for Ash; migrations, custom queries, full-text search support | HIGH |

### Authentication

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| AshAuthentication | ~> 4.13 | Auth framework | Declarative auth strategies (email/password) integrated with Ash resources and policies; admin-created accounts fit naturally | HIGH |
| AshAuthenticationPhoenix | ~> 2.15 | Auth UI | Pre-built LiveView components for login flows; sign-up can be disabled since accounts are admin-created | HIGH |

### Database

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| PostgreSQL | >= 15 | Primary database | ACID transactions, full-text search via tsvector, JSONB for rich text storage, advisory locks for Oban, proven at scale | HIGH |
| Postgrex | ~> 0.19 | Postgres driver | Standard Elixir Postgres adapter, required by AshPostgres and Oban | HIGH |

### Real-Time Infrastructure

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Phoenix PubSub (PG2) | ~> 2.1 | Message broadcasting | Built-in distributed PubSub using Distributed Erlang; no external dependency; handles 100+ users on a single node trivially | HIGH |
| Phoenix Presence | (bundled with Phoenix) | Online/offline tracking | CRDT-based presence tracking with no external deps; self-healing, no single point of failure; scales across cluster nodes automatically | HIGH |
| Phoenix Channels | (bundled with Phoenix) | WebSocket transport | Typing indicators and presence updates over persistent WebSocket connections; LiveView uses Channels underneath | HIGH |

**Why NOT Redis for PubSub/Presence:**
At 100+ concurrent users (the stated scale target), Phoenix's native PG2 adapter is dramatically overqualified. Redis adds operational complexity (another service to deploy, monitor, configure) for zero benefit at this scale. The PG2 adapter handles direct node-to-node communication and only becomes a consideration beyond ~20 clustered nodes. For a single-node or small-cluster deployment serving 100+ users, Redis is unnecessary overhead.

### Background Jobs

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Oban | ~> 2.20 | Job queue | PostgreSQL-backed (no Redis); durable, retryable jobs; CRON scheduling; unique jobs; telemetry; the undisputed standard in Elixir | HIGH |
| AshOban | ~> 0.7.2 | Ash + Oban integration | Declarative job triggers on Ash resources; scheduled actions defined in resource DSL; keeps job definitions co-located with domain logic | HIGH |

**Why Oban over alternatives:**
- **Verk/Kiq/Flume** (Redis-backed): All unmaintained. Do not use.
- **Broadway**: Data ingestion pipeline (Kafka/SQS), not a background job processor. Wrong tool.
- **GenServer/Task**: Ephemeral, no persistence, no retries. Use for fire-and-forget only (e.g., broadcasting a PubSub event).
- **Oban Pro** (commercial): Consider later for rate limiting, workflow orchestration, or batch processing. Not needed for v1.

**Use cases in Astraplex:**
- Email notification delivery (async, retryable)
- Push notification delivery
- File processing (thumbnail generation)
- Cleanup jobs (pruning old typing indicators, expired tokens)
- Audit log writes (if decoupled from request path)

### File Uploads & Storage

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Phoenix LiveView Uploads | (bundled) | Upload handling | Built-in drag-and-drop, progress tracking, file validation, chunked uploads; direct-to-S3 presigned URL support | HIGH |
| ExAws.S3 | ~> 2.5.9 | S3 client | Presigned URL generation, multipart uploads, bucket operations; works with any S3-compatible store (AWS, DigitalOcean Spaces, MinIO) | HIGH |
| ExAws | ~> 2.5 | AWS SDK core | Core HTTP client and credential handling for ExAws.S3 | HIGH |

**Upload architecture:**
1. LiveView validates file type/size client-side and server-side
2. Server generates presigned S3 URL via ExAws.S3
3. Client uploads directly to S3 (bypasses Phoenix, no memory pressure)
4. On completion, LiveView `consume_uploaded_entries/3` persists the S3 URL to the message record
5. Image thumbnails generated via Oban job post-upload

**Why NOT local storage:** S3-compatible storage is horizontally scalable, CDN-friendly, and avoids tying file storage to application server disk. Even for v1, start with S3 to avoid a migration later.

### Email & Notifications

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Swoosh | ~> 1.23 | Email delivery | 30+ provider adapters (SendGrid, SES, Mailgun, SMTP); test adapter for dev; local mailbox preview; Phoenix default | HIGH |
| WebPushElixir | ~> 1.0 | Browser push notifications | VAPID-based Web Push Protocol (RFC 8291/8292); simple API; actively maintained (updated Feb 2026) | MEDIUM |

**Why NOT Pigeon:** Pigeon handles iOS/Android native push. Astraplex is web-first (LiveView), so browser push via the Web Push API is the right choice. If native mobile is added later, Pigeon can be introduced then.

**Notification delivery pattern:**
1. Message received -> Ash notifier triggers
2. In-app notification: Direct PubSub broadcast to connected users (instant, no queue)
3. Email notification: Oban job queued with Swoosh delivery (retryable, rate-limitable)
4. Browser push: Oban job queued with WebPushElixir (retryable)
5. Respect per-user mute preferences before dispatching

### Rich Text & Mentions

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| TipTap (JS) | v2.x | Rich text editor | ProseMirror-based; built-in mention extension with autocomplete; extensible; best-in-class DX; works via LiveView JS hooks | MEDIUM |
| TipTap Mention Extension | (bundled with TipTap) | @mention support | Configurable suggestion/autocomplete popup; renders mention nodes in editor; outputs structured JSON | MEDIUM |

**Integration pattern with LiveView:**
1. TipTap runs client-side via a LiveView JS Hook
2. Hook pushes editor content (JSON or HTML) to server on submit
3. Server-side: Parse TipTap JSON to extract mention node user IDs for notification routing
4. Store message body as TipTap JSON in a JSONB column (preserves structure for rendering)
5. Render stored messages by converting TipTap JSON to HTML server-side, or send JSON to client-side TipTap renderer

**Why TipTap over alternatives:**
- **Quill**: Less extensible, weaker mention support, dated architecture
- **Slate**: Lower-level than TipTap, more work for same result
- **Draft.js**: React-specific, Facebook has deprioritized it
- **Textarea + Markdown**: Poor UX for non-technical users; no inline formatting preview

**Confidence note:** TipTap + LiveView hook integration is a proven pattern with community examples, but mention autocomplete requires querying user lists via the hook (pushEvent to LiveView, receive suggestions, render popup). This is custom work, not a drop-in component.

### Search

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| PostgreSQL Full-Text Search | (built into Postgres) | Message search | tsvector/tsquery with GIN index; no external service; handles message search at 100+ user scale trivially | HIGH |

**Implementation:**
- Add a generated `search_vector` tsvector column to the messages table
- Create a GIN index on the column
- Use `to_tsvector('english', body_text)` with a trigger or generated column
- Query with `to_tsquery` and rank results with `ts_rank`
- AshPostgres supports custom Ecto fragments for full-text queries

**Why NOT Elasticsearch/Meilisearch:** Overkill for 100+ users. Postgres full-text search is fast, well-understood, zero additional infrastructure. Revisit only if search requirements grow beyond what Postgres can handle (unlikely at this scale).

### Admin Tooling

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| AshAdmin | ~> 0.14 | Dev/admin dashboard | Auto-generated CRUD UI from Ash resources; useful for debugging and admin operations during development; consider for production admin | MEDIUM |

**Note:** AshAdmin is excellent for development and internal admin use but may need custom LiveView pages for production admin workflows (user management, channel administration, audit log viewing). Start with AshAdmin, build custom admin views as needed.

### Supporting Libraries

| Library | Version | Purpose | When to Use | Confidence |
|---------|---------|---------|-------------|------------|
| Flop | ~> 0.26 | Pagination/filtering/sorting | Message history pagination, user lists, channel lists; cursor-based pagination for infinite scroll | HIGH |
| FlopPhoenix | ~> 0.23 | Flop LiveView components | Sortable tables, pagination UI components | HIGH |
| Jason | ~> 1.4 | JSON encoding/decoding | TipTap JSON storage, API responses | HIGH |
| Finch | ~> 0.18 | HTTP client | Used by Swoosh and ExAws; connection pooling | HIGH |
| Ecto | ~> 3.12 | Database toolkit | Underlying Ash data layer; migrations, changesets | HIGH |

### Development & Testing

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| Credo | ~> 1.7 | Linting | HIGH |
| Dialyxir | ~> 1.4 | Type checking | HIGH |
| ExMachina | ~> 2.8 | Test factories | HIGH |
| Mox | ~> 1.2 | Mock definitions | HIGH |
| Floki | ~> 0.36 | HTML parsing (test assertions) | HIGH |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| PubSub | Phoenix PG2 | Redis PubSub | Unnecessary at 100-user scale; adds ops complexity |
| Job Queue | Oban | Broadway | Broadway is for stream ingestion, not background jobs |
| Job Queue | Oban | Verk/Kiq | Unmaintained; Redis dependency |
| File Storage | S3 (ExAws) | Local disk | Not scalable; can't CDN; migration pain later |
| Rich Text | TipTap | Quill/Slate | Weaker mention support; more custom work |
| Search | Postgres FTS | Elasticsearch | Massive overkill for 100+ users |
| Email | Swoosh | Bamboo | Swoosh is the Phoenix default since Phoenix 1.6; Bamboo is older |
| Auth | AshAuthentication | Guardian/Pow | AshAuthentication integrates natively with Ash policies and resources |
| Presence | Phoenix Presence | Custom Redis tracking | Phoenix Presence is CRDT-based, self-healing, zero deps |

## Installation

```bash
# Core Ash + Phoenix
mix igniter.install ash ash_postgres ash_phoenix ash_authentication ash_authentication_phoenix

# Background jobs
mix igniter.install ash_oban

# Admin dashboard
mix igniter.install ash_admin

# File uploads (add to mix.exs deps)
# {:ex_aws, "~> 2.5"},
# {:ex_aws_s3, "~> 2.5"},
# {:sweet_xml, "~> 0.7"},  # Required by ExAws

# Email
# {:swoosh, "~> 1.23"},  # Already included by Phoenix generator
# {:finch, "~> 0.18"},   # Already included by Phoenix generator

# Push notifications
# {:web_push_elixir, "~> 1.0"},

# Pagination
# {:flop, "~> 0.26"},
# {:flop_phoenix, "~> 0.23"},

# JSON
# {:jason, "~> 1.4"},  # Already included by Phoenix generator

# Dev/Test
# {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
# {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
# {:ex_machina, "~> 2.8", only: :test},
# {:mox, "~> 1.2", only: :test},
# {:floki, "~> 0.36", only: :test},
```

### JavaScript Dependencies (assets/)

```bash
cd assets
npm install @tiptap/core @tiptap/pm @tiptap/starter-kit @tiptap/extension-mention
```

## Version Verification Sources

| Package | Source | Verified Date |
|---------|--------|---------------|
| Phoenix 1.8.5 | [hex.pm/packages/phoenix](https://hex.pm/packages/phoenix) | 2026-03-09 |
| LiveView 1.1.26 | [hex.pm/packages/phoenix_live_view](https://hex.pm/packages/phoenix_live_view) | 2026-03-09 |
| Ash 3.19.3 | [hexdocs.pm/ash](https://hexdocs.pm/ash/what-is-ash.html) | 2026-03-09 |
| AshPostgres 2.6.32 | [hexdocs.pm/ash_postgres](https://hexdocs.pm/ash_postgres/) | 2026-03-09 |
| AshPhoenix 2.3.20 | [hex.pm/packages/ash_phoenix](https://hex.pm/packages/ash_phoenix) | 2026-03-09 |
| AshAuthentication 4.13.7 | [hexdocs.pm/ash_authentication](https://hexdocs.pm/ash_authentication/) | 2026-03-09 |
| AshAuthenticationPhoenix 2.15.0 | [hexdocs.pm/ash_authentication_phoenix](https://hexdocs.pm/ash_authentication_phoenix/) | 2026-03-09 |
| AshOban 0.7.2 | [hex.pm/packages/ash_oban](https://hex.pm/packages/ash_oban) | 2026-03-09 |
| Oban 2.20.3 | [hexdocs.pm/oban](https://hexdocs.pm/oban/Oban.html) | 2026-03-09 |
| Swoosh 1.23.0 | [hexdocs.pm/swoosh](https://hexdocs.pm/swoosh/Swoosh.html) | 2026-03-09 |
| ExAws.S3 2.5.9 | [hexdocs.pm/ex_aws_s3](https://hexdocs.pm/ex_aws_s3/ExAws.S3.html) | 2026-03-09 |
| Flop 0.26.3 | [hexdocs.pm/flop](https://hexdocs.pm/flop/Flop.html) | 2026-03-09 |

## Key Architectural Decisions Driven by Stack

1. **No Redis dependency.** Postgres handles jobs (Oban), PubSub uses Distributed Erlang (PG2), Presence uses CRDTs. Single database, single runtime. Simpler operations.

2. **Ash as the domain boundary.** All business logic flows through Ash actions. Authorization via Ash policies. Cross-domain communication via public Ash actions. This is the blueprint for future verticals.

3. **Direct-to-S3 uploads.** Phoenix never buffers large files. Presigned URLs keep upload traffic off the application server.

4. **TipTap JSON storage.** Store rich text as structured JSON (not HTML). Enables server-side mention extraction, re-rendering, and future format changes without data migration.

5. **Oban for everything async.** Notifications, email, push, file processing, cleanup. One queue system, one monitoring approach, all backed by the same Postgres instance.
