# Feature Research

**Domain:** Real-time internal messaging platform for multi-property businesses
**Researched:** 2026-03-09
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing any of these and the product feels broken for an internal messaging tool.

#### Messaging Core

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Real-time message delivery | Slack/Teams/Discord have trained all users to expect instant delivery. Anything with visible latency feels broken. | MEDIUM | Phoenix PubSub handles this natively. The complexity is in reliable delivery confirmation, not the transport. |
| Channels (organized conversations) | The fundamental organizing unit of team messaging since Slack popularized it. Users cannot function without topic/team-based groupings. | MEDIUM | Admin-created, invite-only per PROJECT.md. Scoping to properties is the novel part. |
| Direct messages (1:1) | Every messaging platform has DMs. Users need private conversation without creating a channel. | LOW | Simpler than channels -- no membership management, just two users. |
| Group messages (ad-hoc, 2+ people) | Quick multi-person conversations without the overhead of a formal channel. Slack calls these "group DMs." | MEDIUM | Key distinction from channels: no admin control, any participant can create. Need clear UX boundary between group DMs and channels. |
| Single-depth reply threading | Threading is expected in team messaging. Slack's thread model is the standard. Single-depth avoids the Reddit/HN nesting chaos. | MEDIUM | Per PROJECT.md constraint. Display challenges: thread panel vs inline expansion. Must track "thread participant" for notifications. |
| Rich text messages | Users expect basic formatting: bold, italic, code blocks, links. Plain text only feels like 2005. | MEDIUM | TipTap editor via LiveView JS hook. Outputs structured JSON stored in JSONB column. Enables mention nodes, inline formatting, and future extensibility. |
| @mentions (users) | Tagging people to get their attention is fundamental. Missing this breaks notification relevance entirely. | MEDIUM | TipTap mention extension provides autocomplete UI. Server-side extraction of mention nodes for notification routing. |
| Emoji reactions | Quick acknowledgment without cluttering the conversation. Every major messaging platform has this. | LOW | Simple junction table: message_id + user_id + emoji. Display as counts with user lists on hover. |
| File uploads (images inline) | Sharing screenshots, documents, photos is expected. Images should render inline, not as download links. | HIGH | Direct-to-S3 via LiveView uploads with presigned URLs. Images inline, other files as download cards. |
| Unread indicators & badges | Users must know what is new. Per-channel/conversation unread counts are the minimum. Without this, users miss messages. | HIGH | Watermark pattern: last_read_message_id on membership record. Unread count = messages after watermark. High write volume but O(1) check. |
| Search | Finding past messages is critical for a work tool. Users will search for decisions, links, files. | MEDIUM | Postgres full-text search via tsvector with GIN index. Sufficient for 100+ users. |
| User presence (online/offline) | Knowing who is available before messaging them. All major platforms show green/yellow/red dots. | MEDIUM | Ephemeral state via Phoenix Presence (CRDT-based, built for this). Do not persist to database -- purely in-memory. |
| Typing indicators | "User is typing..." creates conversational flow. Expected in real-time messaging. | LOW | Ephemeral PubSub broadcast. Debounce on client (send every 3-5 seconds while typing). Auto-expire after timeout. Never persist. |
| Notifications (in-app + browser push) | Users not looking at the app must still know about important messages. In-app badges + browser push notifications are the minimum. | HIGH | Three tiers: in-app (always), browser push (Web Push API via service worker), email (digest or per-message for offline users). Notification preferences per conversation. |
| Mute conversations | Users need to silence noisy channels without leaving them. Every platform has this. | LOW | Boolean flag on membership record. Suppress push/email notifications but still show unread badge (or not, configurable). |
| Channel/conversation membership management | Admin adds/removes members from channels. Users see who is in a conversation. | MEDIUM | Admin-only for channels (per PROJECT.md). Self-managed for group DMs (leave, but cannot remove others). |

#### Administration

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| User account management (admin-created) | Internal tool -- admin controls who has access. No self-signup. Standard for business tools. | MEDIUM | CRUD for users, role assignment, property assignment, account deactivation (soft delete, preserve message history). |
| Role-based access (Admin vs Staff) | Two roles per PROJECT.md. Admin sees everything, Staff sees property-scoped content. | MEDIUM | Ash policies handle this well. The complexity is in property-scoping rules for channels and conversations. |
| Multi-property user assignment | Staff work across properties. Must see content for all assigned properties. | MEDIUM | Many-to-many: users <-> properties. Channel visibility derived from property membership. Cross-property channels are the tricky edge case. |
| Admin message deletion | Messages are immutable by users, but admin needs moderation capability. | LOW | Soft delete (mark as deleted, show "[message removed by admin]" placeholder). Log the action in audit trail. |
| Audit logging | Tracking admin actions is required for any business tool. Who did what, when. | MEDIUM | Log: user creation/deactivation, role changes, property assignments, channel creation/deletion, member additions/removals, message deletions. Append-only table. |

### Differentiators (Competitive Advantage)

Features that set Astraplex apart from generic Slack/Teams. These align with the multi-property business context.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Property-scoped channel visibility | Staff only see channels for their assigned properties. This is not how Slack/Teams work -- they show everything. For multi-property businesses, information scoping prevents noise and confusion. | HIGH | This is the core differentiator. Channels belong to a property (or are cross-property). Visibility rules cascade from property membership. Requires careful Ash policy design. |
| Cross-property channels (admin-controlled) | Admin creates channels spanning multiple properties for coordination (e.g., "all-managers"). Generic platforms have no concept of this. | MEDIUM | Needs a channel-to-properties mapping. Admin explicitly selects which properties a channel spans. Staff sees the channel if they belong to ANY of the channel's properties. |
| Read receipts (seen-by indicators) | Not standard in Slack (only in enterprise). Valuable for internal teams where knowing a message was read matters ("Did the night shift see this?"). | MEDIUM | Track per-user, per-message read state. Display as "Seen by X, Y, Z" on messages. Privacy consideration: this is an internal business tool, so transparency is appropriate. |
| New member full history access | When someone joins a channel, they see all past messages. Slack does this for public channels but not private. For internal tools, context continuity matters. | LOW | Simply do not filter by join date. This is actually simpler than the alternative. |
| Email notifications for offline users | When a staff member is offline and gets an important message, email ensures they see it. Critical for shift-based workers who are not always at a computer. | MEDIUM | Oban job: after N minutes of no read receipt, send email digest. Batch messages to avoid email flood. Respect mute settings. |
| Immutable message history | Messages cannot be edited or deleted by users. Creates a reliable record. Important for businesses where communication is part of operational record-keeping. | LOW | This is a constraint, not a feature to build. Simply do not implement edit/delete actions for non-admin users. The value is in the trust it creates. |

### Anti-Features (Do Not Build)

Features that seem good but create problems, especially for a v1 internal tool.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Message editing by users | "I made a typo." Slack and Teams both allow it. | Undermines the immutable message trail that is Astraplex's design principle. Edited messages create confusion ("I saw a different message earlier"). Edit history UI adds complexity. | Immutable messages by design. Users can send a follow-up correction. Admin can delete truly problematic messages. |
| Nested/deep threading | "Replies to replies" like Reddit. Seems like better organization. | Creates unreadable UI at depth > 1. Fragments conversations. Users lose track of where the "main" discussion is. Slack explicitly warns against this pattern. | Single-depth threading. Reply to the original message. Start a new thread if the topic shifts. |
| Video/voice calls | "We need video meetings too." Natural extension of messaging. | Completely different technical domain (WebRTC, TURN/STUN servers, media processing). Massive scope increase. Zoom/Meet already exist. | Out of scope per PROJECT.md. Link to external video tool if needed. |
| Bots and integrations | "We want automated messages from our other systems." | Integration framework is a product in itself. API design, webhook management, authentication, rate limiting. Premature for v1. | Defer to future vertical per PROJECT.md. Design Ash action boundaries cleanly so integrations can hook in later. |
| Self-signup / OAuth / SSO | "Users should be able to sign up themselves." | Internal business tool -- admin controls access. Self-signup creates access control headaches. SSO adds auth complexity. | Admin-created accounts with email/password for v1. SSO deferred per PROJECT.md. |
| Message pinning/bookmarking | "I want to save important messages." Slack has pinned messages. | Adds UI complexity and a feature that is rarely used in practice. Pinned messages become stale and ignored. | Deferred per PROJECT.md. Search is the better way to find important messages. |
| @everyone / global broadcast | "I need to message all users at once." Seems useful for announcements. | Creates notification fatigue. In a multi-property org, most "everyone" messages are irrelevant to most people. Abused quickly. | @channel (all members of current channel) is sufficient. Admin creates announcement channels per property. |
| Custom emoji / GIF integration | "We want Giphy and custom emoji like Slack." Fun, engagement-driving. | Giphy integration has licensing costs and content moderation issues. Custom emoji is a feature management surface. Neither is essential for an internal business tool. | Standard Unicode emoji for reactions. Defer custom emoji and GIF integration. |
| Real-time collaborative document editing | "We should be able to co-edit documents." Teams does this with Office integration. | This is an entirely separate product category (OT/CRDT algorithms, document storage, conflict resolution). | Out of scope. Use external tools (Google Docs, Notion). |

## Feature Dependencies

```
[User Accounts & Auth]
    +-- [Role-Based Access (Admin/Staff)]
    |       +-- [Property Assignment]
    |               +-- [Property-Scoped Channel Visibility]  (differentiator)
    |               +-- [Cross-Property Channels]              (differentiator)
    |
    +-- [Channels]
    |       +-- [Channel Membership]
    |       |       +-- [Unread Indicators]
    |       |       +-- [Mute]
    |       |       +-- [Notifications]
    |       |               +-- [Email Notifications]
    |       |
    |       +-- [Messages]
    |               +-- [Rich Text (TipTap)]
    |               +-- [File Uploads]
    |               +-- [Reactions]
    |               +-- [Mentions] ----enhances----> [Notifications]
    |               +-- [Threading]
    |               |       +-- [Thread Notifications]
    |               +-- [Read Receipts]
    |               +-- [Search]
    |               +-- [Admin Message Deletion] ----> [Audit Log]
    |
    +-- [Direct Messages]
    |       +-- (same message features as Channels)
    |
    +-- [Group Messages]
            +-- (same message features as Channels)

[Phoenix Presence]
    +-- [Online/Offline Status]
    +-- [Typing Indicators]

[Admin Actions] ----> [Audit Log]
```

### Dependency Notes

- **Channels require User Accounts & Property Assignment:** Cannot scope channels to properties without the property model existing first.
- **Notifications require Channel Membership + Mentions:** Notification routing depends on membership records and mention parsing. Must build membership tracking before notification delivery.
- **Unread Indicators require Messages + Membership:** Need to track read cursors per user per conversation, so both the message stream and the membership join must exist.
- **Search requires Messages:** Also requires deciding on Postgres full-text search indexing strategy early so messages are indexed from day one.
- **Read Receipts require Unread Indicators:** Read receipts are an extension of read-position tracking. Build the cursor system first, then expose it as "seen by" UI.
- **Property-Scoped Visibility requires Property Assignment + Channel Membership:** The differentiating feature depends on the foundational access model being solid.
- **Email Notifications require Notifications + Background Jobs (Oban):** Cannot send email without a job queue for async processing.

## MVP Definition

### Launch With (v1)

Minimum viable product -- what is needed for the platform to be usable by a multi-property business.

- [ ] **User account management** -- Admin creates/deactivates accounts, assigns roles and properties
- [ ] **Property model** -- Properties exist, staff assigned to properties
- [ ] **Channels** -- Admin-created, invite-only, property-scoped
- [ ] **Direct messages** -- 1:1 between any two users
- [ ] **Group messages** -- Ad-hoc multi-person conversations
- [ ] **Real-time message delivery** -- Messages appear instantly via PubSub
- [ ] **Rich text** -- TipTap editor with formatting (bold, italic, code, links)
- [ ] **@mentions** -- @user notifications via TipTap mention extension
- [ ] **Emoji reactions** -- React to messages
- [ ] **Single-depth threading** -- Reply to messages
- [ ] **Unread indicators** -- Per-channel/conversation unread counts
- [ ] **Online/offline presence** -- Green dot via Phoenix Presence
- [ ] **Typing indicators** -- Ephemeral "user is typing"
- [ ] **In-app notifications** -- Badge counts, notification list
- [ ] **Mute conversations** -- Silence notifications per conversation
- [ ] **Admin message deletion** -- Moderation capability
- [ ] **Basic search** -- Postgres full-text search across messages
- [ ] **Audit log** -- Admin action tracking

### Add After Validation (v1.x)

Features to add once core messaging is working and users are active.

- [ ] **File uploads (images inline)** -- Add after core messaging works; requires S3 infrastructure
- [ ] **Read receipts (seen-by)** -- Add after unread tracking is solid; builds on same cursor system
- [ ] **Browser push notifications** -- Add after in-app notifications work; requires service worker setup
- [ ] **Email notifications** -- Add after push notifications; requires email provider integration and Oban jobs
- [ ] **Cross-property channels** -- Add after single-property channels work; admin creates channels spanning properties
- [ ] **@channel and @here mentions** -- Add after @user mentions; broadcast to all members or online members

### Future Consideration (v2+)

- [ ] **Message pinning/bookmarking** -- Deferred per PROJECT.md
- [ ] **OAuth/SSO** -- Deferred per PROJECT.md
- [ ] **Bots and integrations** -- Future vertical
- [ ] **Mobile native app** -- LiveView web works on mobile browsers
- [ ] **Advanced search** -- Full-text with filters (by user, date range, channel, has:file)
- [ ] **Message export / compliance** -- Bulk export for legal/compliance needs

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| User accounts & auth | HIGH | MEDIUM | P1 |
| Property model & assignment | HIGH | MEDIUM | P1 |
| Channels (property-scoped) | HIGH | HIGH | P1 |
| Direct messages | HIGH | MEDIUM | P1 |
| Group messages | MEDIUM | MEDIUM | P1 |
| Real-time delivery (PubSub) | HIGH | MEDIUM | P1 |
| Rich text (TipTap) | MEDIUM | MEDIUM | P1 |
| @user mentions | HIGH | MEDIUM | P1 |
| Emoji reactions | MEDIUM | LOW | P1 |
| Single-depth threading | HIGH | MEDIUM | P1 |
| Unread indicators | HIGH | HIGH | P1 |
| Presence (online/offline) | MEDIUM | LOW | P1 |
| Typing indicators | LOW | LOW | P1 |
| In-app notifications | HIGH | MEDIUM | P1 |
| Mute conversations | MEDIUM | LOW | P1 |
| Admin message deletion | MEDIUM | LOW | P1 |
| Basic search | HIGH | MEDIUM | P1 |
| Audit log | MEDIUM | MEDIUM | P1 |
| File uploads | HIGH | HIGH | P2 |
| Read receipts | MEDIUM | MEDIUM | P2 |
| Browser push notifications | HIGH | MEDIUM | P2 |
| Email notifications | HIGH | HIGH | P2 |
| Cross-property channels | HIGH | MEDIUM | P2 |
| @channel/@here mentions | MEDIUM | LOW | P2 |
| Message pinning | LOW | LOW | P3 |
| SSO/OAuth | MEDIUM | HIGH | P3 |
| Bots/integrations | LOW | HIGH | P3 |
| Advanced search filters | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add in early iterations
- P3: Nice to have, future consideration

## Sources

- [Slack vs Teams comparison (Nuacom)](https://nuacom.com/slack-vs-teams-comparison-for-best-business-collaboration-tools/)
- [Ably: What it takes to build a realtime messaging app](https://ably.com/blog/what-it-takes-to-build-a-realtime-chat-or-messaging-app)
- [TipTap Mention Extension](https://tiptap.dev/docs/editor/extensions/nodes/mention)
- [Phoenix LiveView Upload Deep Dive](https://www.phoenixframework.org/blog/phoenix-live-view-upload-deep-dive)
- [TipTap rich text editor overview 2025](https://liveblocks.io/blog/which-rich-text-editor-framework-should-you-choose-in-2025)

---
*Feature research for: Astraplex -- real-time internal messaging platform*
*Researched: 2026-03-09*
