# Requirements: Astraplex

**Defined:** 2026-03-09
**Core Value:** Staff and admins can communicate in real time with messages that arrive instantly, scoped to conversations they are members of.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Engineering Quality

- [ ] **QUAL-01**: Integration test suite covering Ash actions, policies, and PubSub behavior
- [ ] **QUAL-02**: E2E test suite covering full user flows through LiveView (tool TBD by research)
- [ ] **QUAL-03**: Static analysis and compile-time type checking (tools TBD by research)
- [ ] **QUAL-04**: Git pre-commit hook (format check, compile, static analysis)
- [ ] **QUAL-05**: Git pre-push hook (run test suite)
- [ ] **QUAL-06**: Test harness with standardized setup, factories, and helper modules
- [ ] **QUAL-07**: AI usage rules (CLAUDE.md) encoding code conventions, architecture rules, commit conventions
- [ ] **QUAL-08**: Design system with consistent component library (selection TBD by research)

### AI Tooling

- [ ] **AI-01**: Ash AI integration (use case TBD by research)
- [ ] **AI-02**: MCP server exposing Ash domains as tools for AI agents

### Foundation

- [ ] **FOUND-01**: Admin can create user accounts with email and password
- [ ] **FOUND-02**: Admin can assign users the Admin or Staff role
- [ ] **FOUND-03**: Admin can deactivate user accounts (soft delete, preserves message history)
- [ ] **FOUND-04**: User can log in with email and password
- [ ] **FOUND-05**: User session persists across browser refresh
- [ ] **FOUND-06**: User can log out from any page

### Channels

- [ ] **CHAN-01**: Admin can create a channel with a name and description
- [ ] **CHAN-02**: Admin can invite users to a channel
- [ ] **CHAN-03**: Admin can remove users from a channel
- [ ] **CHAN-04**: User can view list of channels they are a member of
- [ ] **CHAN-05**: New channel members can see full message history
- [ ] **CHAN-06**: Admin can archive a channel (no new messages, history preserved)

### Direct Messages

- [ ] **DM-01**: User can start a 1:1 direct message with any other user
- [ ] **DM-02**: User can view list of their DM conversations
- [ ] **DM-03**: DM conversations are visible only to the two participants

### Group Messages

- [ ] **GRP-01**: User can create an ad-hoc group conversation by selecting 2+ users
- [ ] **GRP-02**: User can view list of their group conversations
- [ ] **GRP-03**: Group conversations are visible only to participants
- [ ] **GRP-04**: User can leave a group conversation

### Messaging Core

- [ ] **MSG-01**: User can send a plain text message in any conversation they are a member of
- [ ] **MSG-02**: User can send rich text messages (bold, italic, code blocks, links)
- [ ] **MSG-03**: User can @mention other members in a message
- [ ] **MSG-04**: User can add emoji reactions to messages
- [ ] **MSG-05**: User can remove their own reactions
- [ ] **MSG-06**: User can reply to a message (single-depth threading)
- [ ] **MSG-07**: Replies attach to parent message only — no nested replies
- [ ] **MSG-08**: Messages are immutable — users cannot edit or delete their own messages
- [ ] **MSG-09**: Admin can delete any message (soft delete, shows "[message removed]" placeholder)
- [ ] **MSG-10**: Messages appear in real time without page refresh for all conversation members

### Presence & Indicators

- [ ] **PRES-01**: User can see online/offline status of other users
- [ ] **PRES-02**: User can see "user is typing..." indicator in conversations
- [ ] **PRES-03**: User can see unread message count per channel and conversation
- [ ] **PRES-04**: User can see read receipts (seen-by indicators) on messages
- [ ] **PRES-05**: User can mute a channel or conversation (silences notifications, stays visible)

### Notifications

- [ ] **NOTF-01**: User receives in-app notification badges for new messages
- [ ] **NOTF-02**: User receives browser push notifications for new messages (when app not focused)
- [ ] **NOTF-03**: Email notification pipeline established with stubbed delivery (Oban job queue pattern in place, actual email provider swapped in later)
- [ ] **NOTF-04**: Muted conversations do not trigger push or email notifications
- [ ] **NOTF-05**: User receives notification when @mentioned

### Administration

- [ ] **ADMN-01**: Admin can view and manage all user accounts
- [ ] **ADMN-02**: Admin can view and manage all channels
- [ ] **ADMN-03**: Audit log records admin actions (user creation, deactivation, role changes, channel management, message deletion)
- [ ] **ADMN-04**: Admin can view audit log with filtering

### UI & Design

- [ ] **UI-01**: Mobile-first responsive layout (single-panel on mobile, multi-panel on desktop)
- [ ] **UI-03**: PWA — installable on home screen with app-like experience
- [ ] **UI-04**: Sidebar navigation for channels, DMs, and group conversations

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Properties & Multi-Site

- **PROP-01**: Properties domain with property resources
- **PROP-02**: Staff assignment to one or more properties
- **PROP-03**: Property-based filtering and organization for scheduling vertical

### File Uploads

- **FILE-01**: User can upload files with messages (images render inline, other files as download links)

### Search

- **SRCH-01**: User can search message history across conversations they are a member of
- **SRCH-02**: Search results show message context (channel/conversation, sender, timestamp)

### Enhanced Messaging

- **EMSG-01**: Message pinning to channels
- **EMSG-02**: Personal message bookmarks
- **EMSG-03**: @channel and @here mentions (broadcast to all/online members)
- **EMSG-04**: Advanced search with filters (by user, date range, channel, has:file)

### Authentication

- **AUTH-01**: OAuth/SSO login (Google, etc.)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Property-scoped channel visibility | Properties irrelevant to messaging — access is membership-based. Properties deferred to scheduling vertical. |
| Message editing by users | Immutable by design — preserves audit trail and prevents confusion |
| Nested/deep threading | Single-depth only — avoids unreadable UI and fragmented conversations |
| Video/voice calls | Different technical domain (WebRTC). Use external tools. |
| Bots and integrations | Future vertical — design Ash action boundaries so integrations can hook in later |
| Self-signup | Internal business tool — admin controls access |
| Custom emoji / GIF integration | Not essential for internal business tool |
| Real-time document editing | Separate product category (OT/CRDT). Use external tools. |
| Unit tests | Integration and E2E provide more value for domain-driven Ash architecture |
| @everyone global broadcast | Creates notification fatigue in multi-property orgs |
| Mobile native app | PWA via LiveView — avoids native app complexity |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| QUAL-01 | Phase 1: Engineering Quality | Pending |
| QUAL-02 | Phase 1: Engineering Quality | Pending |
| QUAL-03 | Phase 1: Engineering Quality | Pending |
| QUAL-04 | Phase 1: Engineering Quality | Pending |
| QUAL-05 | Phase 1: Engineering Quality | Pending |
| QUAL-06 | Phase 1: Engineering Quality | Pending |
| QUAL-07 | Phase 1: Engineering Quality | Pending |
| QUAL-08 | Phase 1: Engineering Quality | Pending |
| AI-01 | Phase 2: AI Tooling | Pending |
| AI-02 | Phase 2: AI Tooling | Pending |
| FOUND-01 | Phase 3: Foundation & Auth | Pending |
| FOUND-02 | Phase 3: Foundation & Auth | Pending |
| FOUND-03 | Phase 3: Foundation & Auth | Pending |
| FOUND-04 | Phase 3: Foundation & Auth | Pending |
| FOUND-05 | Phase 3: Foundation & Auth | Pending |
| FOUND-06 | Phase 3: Foundation & Auth | Pending |
| CHAN-01 | Phase 4: Channels | Pending |
| CHAN-02 | Phase 4: Channels | Pending |
| CHAN-03 | Phase 4: Channels | Pending |
| CHAN-04 | Phase 4: Channels | Pending |
| CHAN-05 | Phase 4: Channels | Pending |
| CHAN-06 | Phase 4: Channels | Pending |
| DM-01 | Phase 5: Conversations | Pending |
| DM-02 | Phase 5: Conversations | Pending |
| DM-03 | Phase 5: Conversations | Pending |
| GRP-01 | Phase 5: Conversations | Pending |
| GRP-02 | Phase 5: Conversations | Pending |
| GRP-03 | Phase 5: Conversations | Pending |
| GRP-04 | Phase 5: Conversations | Pending |
| MSG-01 | Phase 6: Messaging Core | Pending |
| MSG-02 | Phase 6: Messaging Core | Pending |
| MSG-03 | Phase 6: Messaging Core | Pending |
| MSG-04 | Phase 6: Messaging Core | Pending |
| MSG-05 | Phase 6: Messaging Core | Pending |
| MSG-06 | Phase 6: Messaging Core | Pending |
| MSG-07 | Phase 6: Messaging Core | Pending |
| MSG-08 | Phase 6: Messaging Core | Pending |
| MSG-09 | Phase 6: Messaging Core | Pending |
| MSG-10 | Phase 6: Messaging Core | Pending |
| PRES-01 | Phase 7: Presence & Indicators | Pending |
| PRES-02 | Phase 7: Presence & Indicators | Pending |
| PRES-03 | Phase 7: Presence & Indicators | Pending |
| PRES-04 | Phase 7: Presence & Indicators | Pending |
| PRES-05 | Phase 7: Presence & Indicators | Pending |
| NOTF-01 | Phase 8: Notifications | Pending |
| NOTF-02 | Phase 8: Notifications | Pending |
| NOTF-03 | Phase 8: Notifications | Pending |
| NOTF-04 | Phase 8: Notifications | Pending |
| NOTF-05 | Phase 8: Notifications | Pending |
| ADMN-01 | Phase 9: Administration | Pending |
| ADMN-02 | Phase 9: Administration | Pending |
| ADMN-03 | Phase 9: Administration | Pending |
| ADMN-04 | Phase 9: Administration | Pending |
| UI-01 | Phase 10: UI & PWA | Pending |
| UI-03 | Phase 10: UI & PWA | Pending |
| UI-04 | Phase 10: UI & PWA | Pending |

**Coverage:**
- v1 requirements: 56 total
- Mapped to phases: 56
- Unmapped: 0

---
*Requirements defined: 2026-03-09*
*Last updated: 2026-03-09 -- traceability populated during roadmap creation*
