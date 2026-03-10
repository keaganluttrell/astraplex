# Phase 5: Conversations - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

User-initiated conversations: 1:1 DMs and ad-hoc group messages (2+ people), with plain text messaging and real-time delivery. A single unified Conversation resource — DMs and groups are the same thing, distinguished only by member count. Covers DM-01, DM-02, DM-03, GRP-01, GRP-02, GRP-03. GRP-04 (leave group) descoped from v1. Rich text, mentions, reactions, threading added in Phase 6. Presence and unread tracking in Phase 7.

</domain>

<decisions>
## Implementation Decisions

### Unified Data Model
- Single Conversation resource — no separate DM/Group types
- No type field; member count determines behavior: 2 members = DM, 3+ = group
- 1:1 DMs are unique per user pair — starting a DM with someone you've already messaged reopens the existing conversation
- Group conversations are also unique per exact member set — same people = same conversation
- Members are fixed at creation — no adding or removing members after the fact
- No leaving conversations (DMs or groups) — all conversations are permanent
- GRP-04 ("User can leave a group conversation") explicitly descoped from v1

### Starting a Conversation
- Sidebar '+' button in the DMs section opens a drawer with a user picker
- Multi-select user picker: pick 1+ users. 1 user = DM, 2+ = group
- If a conversation with the exact same member set already exists, silently navigate to it (no error or toast)
- Lazy creation: conversation is NOT persisted until the first message is sent — no empty conversations in sidebar
- User picker shows all active users (reuses pattern from channel member picker with client-side email filtering)

### Sidebar Display
- Single "DMs" sidebar section replaces separate "Direct Messages" and "Groups" sections
- Avatar + name display for each conversation
- 1:1 DMs: other person's avatar + name
- Groups: stacked avatars or group icon + first 2 member names + count ("Alice, Bob +3")
- Sorted by most recent activity (newest messages at top)
- Sidebar updates in real-time via PubSub when new conversation is created (lazy — on first message)

### Chat View
- Reuses chat_layout component from Phase 4 (title header, scrollable messages, pinned input bar)
- Chat header shows conversation name + people icon to open member list drawer (read-only)
- Plain text messaging with real-time PubSub delivery (same pattern as channels)
- Message display: messages start at top of scroll area; once full, view pins to bottom with newest messages visible above input bar (cross-cutting — applies to channels too)

### Privacy & Access
- Conversations visible only to participants — no admin visibility into conversations they're not part of
- Admins can only see conversations they are a member of, same as staff
- Admin controls are indirect: deactivating a user prevents them from logging in/sending messages, but their conversations persist for other members
- Deactivated users' conversations remain visible to other members; names display normally (no "(deactivated)" tag per Phase 3 decision)

### Messaging in Phase 5
- Plain text messaging included (not deferred to Phase 6)
- Reuses the existing Message resource — adds conversation_id (allow_nil: true, polymorphic with channel_id)
- PubSub broadcast pattern reused from channels with conversation-scoped topics
- Phase 6 layers rich text, mentions, reactions, threading, and optimistic UI on top

### Claude's Discretion
- Conversation PubSub topic naming convention
- User picker search/filter implementation details
- Stacked avatar vs group icon for multi-person conversations in sidebar
- Member list drawer layout and styling
- Empty state for DMs section when no conversations exist
- Exact scroll behavior implementation (ScrollBottom hook adaptation)
- How lazy creation handles the pre-persist state in the chat view

</decisions>

<specifics>
## Specific Ideas

- "Groups should just be DMs with multiple members" — user's core vision for unified model
- "DMs" as the single section name — not "Direct Messages" or separate "Groups"
- Messages start at top, snap to bottom once page fills — user-specified scroll behavior
- "It is what it is" — conversations are permanent, no leaving, no hiding

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `chat_layout` component (Layouts): title header, scrollable message area, pinned input bar — direct reuse for conversation view
- `empty_state` component (UI): icon + title + description + action slot — for empty DMs section
- `user_avatar` component (UI): initials-based avatar with size variants — for sidebar and member list
- `sidebar_group` component (Layouts): collapsible section with items and add button — currently has "Direct Messages" and "Groups" placeholders to be replaced with single "DMs" section
- `ScrollBottom` JS hook: anchors chat to bottom with auto-scroll — needs adaptation for "start at top" behavior
- `ClearInput` JS hook: resets form after send — reusable for conversation messaging
- Channel member picker (ChannelSettingsDrawer): client-side email filtering for user selection — pattern reusable for conversation user picker

### Established Patterns
- Message resource with polymorphic belongs_to (channel_id allow_nil: true) — add conversation_id similarly
- Phoenix PubSub for real-time message delivery (channel topic: "channel:messages:{channel_id}")
- Phoenix streams for message list rendering with PubSub-driven inserts
- AshPhoenix.Form for form handling
- Drawer pattern for creation/edit flows, modal for destructive confirmations
- Smokestack factories for test data
- SimpleCheck pattern for policies that can't use Ash expressions on create actions

### Integration Points
- Router: needs `/dm/:id` route in authenticated scope (placeholder URL pattern from Phase 3.1)
- Sidebar: replace "Direct Messages" and "Groups" sidebar_groups with single "DMs" group populated with real data
- Layouts: admin_shell/staff_shell need to pass conversation list data to sidebar
- Messaging domain: add Conversation resource + ConversationMembership resource
- Message resource: add conversation_id relationship alongside existing channel_id
- PubSub: conversation-scoped topics for message broadcast
- MCP server: Conversation resource auto-discovered (Phase 2 pattern)

</code_context>

<deferred>
## Deferred Ideas

- Leaving group conversations (GRP-04) — descoped from v1 entirely
- Adding members to existing conversations — future enhancement
- Conversation naming for groups — not in v1, display member names only
- Admin visibility into all conversations — explicitly rejected for privacy
- Conversation search — v2 (SRCH-01/02)
- Muting conversations — Phase 7 (PRES-05)
- Unread badges on conversations — Phase 7 (PRES-03)

</deferred>

---

*Phase: 05-conversations*
*Context gathered: 2026-03-10*
