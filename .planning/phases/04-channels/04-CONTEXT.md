# Phase 4: Channels - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin-managed invite-only channels with membership, basic plain text messaging, and real-time delivery via PubSub. Covers CHAN-01 through CHAN-06: channel creation, member invite/remove, member-scoped channel list, message history for new members, and channel archiving. Messaging Core (Phase 6) layers rich text, mentions, reactions, threading, and optimistic UI on top. Presence and unread tracking come in Phase 7.

</domain>

<decisions>
## Implementation Decisions

### Message Scope
- Phase 4 includes basic plain text message sending in channels (not deferred to Phase 6)
- Messages appear in real-time for all channel members via Phoenix PubSub (basic broadcast)
- Phase 6 adds rich text, mentions, reactions, threading, and optimistic UI on top
- Message resource designed as polymorphic from the start (belongs to channel OR conversation via polymorphic reference)
- Phase 5 (DMs/Groups) reuses the same Message resource — no refactor needed

### Domain Structure
- All resources live in the Messaging domain: `lib/astraplex/messaging/`
- Resources: Channel, Membership, Message (polymorphic)
- Matches PROJECT.md domain split: "Messaging — channels, conversations, messages, threads, reactions, mentions"

### Channel Creation UX
- Full channel management at `/admin/channels` (list, create, edit, archive)
- Sidebar '+' button for quick channel creation (admin-only) — opens a drawer
- Creation form: name (required) + description (optional) — members added separately after creation
- Channel names must be unique (case-insensitive) — validation error on duplicate
- Same drawer component for create and edit modes

### Channel Editing & Archiving
- Settings/gear icon in chat header (admin-only) opens a drawer with name, description, and archive button
- Drawers for edit forms, modals for destructive confirmations (archive = modal confirm)
- Consistent with Phase 3.1 pattern: drawers for edits, modals for destructive actions

### Membership Management
- Channel settings drawer includes a 'Members' section with current member list and 'Add Members' button
- User picker: searchable list of all active users not already in channel, supports multi-select
- Member removal: remove icon per row, confirmation modal ("Remove [Name] from #channel?")
- Creator is NOT auto-added as a member — admin must explicitly add themselves if they want to participate
- All channel members can see the member list (read-only for staff, add/remove for admin only)

### Sidebar Integration
- Channels displayed with `#` prefix: `#general`, `#announcements`
- Sorted alphabetically (A-Z by name) — stable, predictable position
- Active channel highlighted in sidebar
- Archived channels hidden from sidebar — accessible via admin page only
- UUID-based routing: `/channels/:id` (not slug-based)
- Sidebar updates in real-time via PubSub when user is added to a new channel
- Unread badge markup included as hidden placeholder — Phase 7 wires real counts

### Claude's Discretion
- Polymorphic message association pattern (research best Ash approach)
- Channel list pagination on admin page
- Message pagination/infinite scroll in chat view
- PubSub topic naming convention
- Drawer component implementation details
- User picker search/filter implementation
- Empty state content for channels with no messages

</decisions>

<specifics>
## Specific Ideas

- "Less is more" — clean sidebar with just `#name`, no icons per channel
- Drawers for ALL edit forms, modals ONLY for destructive confirmations — this is a hard rule from Phase 3.1
- Unread badges are Phase 7 but sidebar should have the visual slot ready (hidden placeholder)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `chat_layout` component (Layouts): title header, scrollable message area, pinned input bar — ready to use for channel view
- `empty_state` component (UI): icon + title + description + action slot — for empty channels
- `user_avatar` component (UI): initials-based avatar with size variants — for member lists and message display
- `page_header` component (UI): title + action buttons — for admin channel list page
- `breadcrumb` component (UI): navigation trail — for admin pages
- `skeleton_list` component (UI): loading placeholder — for channel list loading state
- DaisyUIComponents: table, modal, badge, button, form_input, drawer, dropdown — all available

### Established Patterns
- AshPhoenix.Form for form handling (used in UserListLive for user creation)
- Modal pattern with JS commands for show/hide (UserListLive :new action)
- Role-based shells: admin_shell/staff_shell with active_page highlighting
- LiveAuth on_mount hooks: :require_authenticated_user, :require_admin
- ash_authentication_live_session for auth-scoped LiveView sessions
- Sidebar `sidebar_group` component with HTML details/summary for collapsible sections — currently shows placeholder text

### Integration Points
- Router: needs new `/channels/:id` route in authenticated scope, `/admin/channels` in admin scope
- Sidebar: `sidebar_group` for "Channels" needs to accept real channel data and render links
- Layouts module: admin_shell/staff_shell need to pass channel list data to sidebar
- MCP server: Messaging domain auto-discovered (Phase 2 decision)
- Smokestack factories: need Channel, Membership, Message factories for tests

</code_context>

<deferred>
## Deferred Ideas

- Unread message tracking and badge counts — Phase 7 (PRES-03)
- Rich text, mentions, reactions, threading — Phase 6 (Messaging Core)
- Channel search/filtering — v2 (SRCH-01/02)
- Channel reordering / pinning — future phase

</deferred>

---

*Phase: 04-channels*
*Context gathered: 2026-03-10*
