# Roadmap: Astraplex

## Overview

Astraplex delivers a real-time internal messaging platform built on Elixir/Phoenix/Ash/LiveView. The roadmap starts with engineering quality foundations (test harness, static analysis, design system, git hooks) and AI tooling, then builds authentication and user management, followed by the three conversation types (channels, DMs, groups), core messaging features (rich text, threading, reactions, real-time), presence and indicators, notifications, administration, and finally the polished mobile-first PWA shell. Each phase delivers a complete, verifiable capability that builds on the previous.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Engineering Quality** - Project scaffold, test harness, static analysis, git hooks, AI usage rules, and design system (completed 2026-03-10)
- [x] **Phase 2: AI Tooling** - MCP server exposing Ash domains as tools for Claude Code during development
- [x] **Phase 3: Foundation & Auth** - Admin-created user accounts, roles, authentication, and session management (completed 2026-03-10)
- [ ] **Phase 3.1: UI Patterns** - App shell layout, sidebar navigation, mobile dock, shared components (INSERTED)
- [ ] **Phase 4: Channels** - Admin-managed invite-only channels with membership and message history
- [ ] **Phase 5: Conversations** - User-initiated DMs (1:1) and ad-hoc group messages (2+)
- [ ] **Phase 6: Messaging Core** - Text and rich text messages, mentions, reactions, threading, and real-time delivery
- [ ] **Phase 7: Presence & Indicators** - Online/offline status, typing indicators, unread counts, read receipts, and mute
- [ ] **Phase 8: Notifications** - In-app badges, browser push, email pipeline (stubbed), mute integration, and mention alerts
- [ ] **Phase 9: Administration** - Admin dashboard for users and channels, audit log with filtering
- [ ] **Phase 10: UI & PWA** - Mobile-first responsive layout, PWA installability, and sidebar navigation

## Phase Details

### Phase 1: Engineering Quality
**Goal**: The project has a working scaffold with enforced code quality, a test harness ready for integration and E2E tests, and a design system for consistent UI
**Depends on**: Nothing (first phase)
**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06, QUAL-07, QUAL-08
**Success Criteria** (what must be TRUE):
  1. Running `mix test` executes the integration test suite with factories and helpers available
  2. Running the E2E test tool executes browser-based tests against a running LiveView app
  3. Git pre-commit hook rejects code that fails formatting, compilation, or static analysis checks
  4. Git pre-push hook rejects pushes when the test suite fails
  5. CLAUDE.md exists with code conventions, architecture rules, and commit conventions that Claude follows
  6. Design system components render consistently and are available for use in LiveView templates
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md -- Scaffold Phoenix/Ash project and establish integration test harness with Smokestack factories
- [ ] 01-02-PLAN.md -- Set up E2E browser testing (PhoenixTestPlaywright) and DaisyUIComponents design system
- [ ] 01-03-PLAN.md -- Configure static analysis (Credo/Dialyxir), git hooks, and create CLAUDE.md conventions

### Phase 2: AI Tooling
**Goal**: AI agents can interact with Ash domains through an MCP server during development, with a System/Health domain validating the pipeline end-to-end
**Depends on**: Phase 1
**Requirements**: AI-01, AI-02
**Success Criteria** (what must be TRUE):
  1. An AI agent (Claude Code) can connect to the MCP server and invoke Ash domain actions as tools
  2. The System/Health domain is accessible via MCP and returns valid health data
  3. New domains added in future phases are auto-discovered by MCP with no config changes
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md -- Add ash_ai, create System/Health domain, wire MCP dev server, configure .mcp.json
- [ ] 02-02-PLAN.md -- Set up production MCP router exposing domain tools (check_health) via AshAi.Mcp.Router

### Phase 3: Foundation & Auth
**Goal**: Admins can create and manage user accounts, and users can securely log in and maintain sessions
**Depends on**: Phase 1
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06
**Success Criteria** (what must be TRUE):
  1. Admin can create a new user account with email and password (no self-signup exists)
  2. Admin can assign a user the Admin or Staff role
  3. Admin can deactivate a user account and that user can no longer log in, but their message history is preserved
  4. User can log in with email/password, refresh the browser, and remain logged in
  5. User can log out from any page and is redirected to the login screen
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md -- Accounts domain with User/Token resources, AshAuthentication, admin CRUD actions, and negative auth tests
- [ ] 03-02-PLAN.md -- Auth web layer: sign-in LiveView, auth controller, LiveAuth hooks, router with protected scopes
- [ ] 03-03-PLAN.md -- Admin user management UI at /admin/users, bootstrap mix task, and dev seeds

### Phase 03.1: UI Patterns (INSERTED)

**Goal:** The app has a real messaging-app shell with role-based layouts, sidebar navigation, mobile dock, shared UI components, and established page-level view patterns that all feature phases build on
**Requirements**: UI-01, UI-04
**Depends on:** Phase 3
**Success Criteria** (what must be TRUE):
  1. Admin and staff users see a 2-panel layout with fixed sidebar and main content area on desktop
  2. Mobile users see a bottom dock with Home, Inbox, Apps, Create navigation instead of sidebar
  3. Sidebar shows Home link, Admin link (admin-only), collapsible Channels/DMs/Groups sections, and user dropdown with sign out and theme toggle
  4. All existing pages (dashboard, admin users) render inside the new shell chrome
  5. Shared UI components (page header, empty state, avatar, skeletons) are available for all future phases
  6. Chat layout pattern is established as a reusable component for messaging phases
**Plans:** 3/3 plans complete

Plans:
- [x] 03.1-01-PLAN.md -- Shared UI components module and role-based shell layouts (top bar, sidebar, user dropdown)
- [x] 03.1-02-PLAN.md -- Mobile dock, bottom sheet, chat layout, wire existing LiveViews into new shells
- [ ] 03.1-03-PLAN.md -- UAT fixes: avatar centering, sidebar icon, breadcrumb top bar, user list sort stability

### Phase 4: Channels
**Goal**: Admins can create invite-only channels, manage membership, and members can view their channels with full message history
**Depends on**: Phase 3
**Requirements**: CHAN-01, CHAN-02, CHAN-03, CHAN-04, CHAN-05, CHAN-06
**Success Criteria** (what must be TRUE):
  1. Admin can create a channel with a name and description, and it appears in the channel list
  2. Admin can invite users to a channel and remove users from a channel
  3. User sees only channels they are a member of in their channel list
  4. A newly invited channel member can scroll back and see the full message history
  5. Admin can archive a channel, preventing new messages while preserving history
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md -- Messaging domain with Channel, Membership, Message resources, policies, PubSub, factories, and integration tests
- [ ] 04-02-PLAN.md -- Admin channel management UI at /admin/channels with create/edit drawers, member management, and archive
- [ ] 04-03-PLAN.md -- Channel chat view, sidebar integration with real channel data, and real-time PubSub messaging

### Phase 5: Conversations
**Goal**: Users can start 1:1 direct messages and ad-hoc group conversations, visible only to participants
**Depends on**: Phase 3
**Requirements**: DM-01, DM-02, DM-03, GRP-01, GRP-02, GRP-03, GRP-04
**Success Criteria** (what must be TRUE):
  1. User can start a 1:1 DM with any other user and both users see it in their DM list
  2. DM conversations are visible only to the two participants -- no other user can see them
  3. User can create a group conversation by selecting 2+ users, and all participants see it in their group list
  4. Group conversations are visible only to participants -- no non-participant can see them
  5. User can leave a group conversation and it disappears from their list
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

### Phase 6: Messaging Core
**Goal**: Users can send plain and rich text messages with mentions, reactions, and single-depth threading, delivered in real time
**Depends on**: Phase 4, Phase 5
**Requirements**: MSG-01, MSG-02, MSG-03, MSG-04, MSG-05, MSG-06, MSG-07, MSG-08, MSG-09, MSG-10
**Success Criteria** (what must be TRUE):
  1. User can send a plain text message and it appears instantly for all members of the conversation without page refresh
  2. User can send rich text (bold, italic, code blocks, links) and it renders correctly for all members
  3. User can @mention another member and the mention renders as a distinct, clickable element
  4. User can add and remove emoji reactions on messages, visible to all conversation members in real time
  5. User can reply to a message creating a single-depth thread; replies attach to the parent and cannot be replied to
  6. Messages cannot be edited or deleted by the sender; admin can delete any message showing a "[message removed]" placeholder
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD
- [ ] 06-03: TBD

### Phase 7: Presence & Indicators
**Goal**: Users see live online/offline status, typing indicators, unread counts, and read receipts across all conversations
**Depends on**: Phase 6
**Requirements**: PRES-01, PRES-02, PRES-03, PRES-04, PRES-05
**Success Criteria** (what must be TRUE):
  1. User can see which other users are currently online or offline, updated in real time
  2. When a user is typing in a conversation, other members see a "user is typing..." indicator
  3. Each channel and conversation shows an accurate unread message count that clears when the user views the conversation
  4. Messages show seen-by indicators so the sender knows who has read them
  5. User can mute a channel or conversation, silencing notifications while keeping it visible in their list
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD

### Phase 8: Notifications
**Goal**: Users receive timely notifications through in-app badges, browser push, and a stubbed email pipeline, respecting mute preferences
**Depends on**: Phase 7
**Requirements**: NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05
**Success Criteria** (what must be TRUE):
  1. User sees in-app notification badges for new messages in conversations they are not currently viewing
  2. User receives browser push notifications for new messages when the app is not focused
  3. Oban job queue processes email notification jobs with stubbed delivery (job enqueues and completes, no actual email sent)
  4. Muted conversations do not trigger push or email notifications
  5. User receives a distinct notification when they are @mentioned in a message
**Plans**: TBD

Plans:
- [ ] 08-01: TBD
- [ ] 08-02: TBD

### Phase 9: Administration
**Goal**: Admins have a dashboard to manage users and channels, with a complete audit trail of admin actions
**Depends on**: Phase 6
**Requirements**: ADMN-01, ADMN-02, ADMN-03, ADMN-04
**Success Criteria** (what must be TRUE):
  1. Admin can view and manage all user accounts from an admin interface (not just individual user pages)
  2. Admin can view and manage all channels from an admin interface
  3. Admin actions (user creation, deactivation, role changes, channel management, message deletion) are recorded in an audit log
  4. Admin can view the audit log and filter entries by action type, user, or date
**Plans**: TBD

Plans:
- [ ] 09-01: TBD
- [ ] 09-02: TBD

### Phase 10: UI & PWA
**Goal**: The application has a polished mobile-first responsive layout with PWA installability and intuitive sidebar navigation
**Depends on**: Phase 6
**Requirements**: UI-01, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. On mobile, the app displays a single-panel layout with navigation; on desktop, it displays a multi-panel layout
  2. The app is installable as a PWA from the browser with an app-like home screen experience
  3. Sidebar navigation provides organized access to channels, DMs, and group conversations
**Plans**: TBD

Plans:
- [ ] 10-01: TBD
- [ ] 10-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 3.1 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10

| Phase                    | Plans Complete | Status      | Completed  |
| ------------------------ | -------------- | ----------- | ---------- |
| 1. Engineering Quality   | 3/3            | Complete    | 2026-03-10 |
| 2. AI Tooling            | 1/2            | In progress | -          |
| 3. Foundation & Auth     | 3/3            | Complete    | 2026-03-10 |
| 3.1. UI Patterns         | 2/3            | In progress | -          |
| 4. Channels              | 2/3 | In Progress|  |
| 5. Conversations         | 0/?            | Not started | -          |
| 6. Messaging Core        | 0/?            | Not started | -          |
| 7. Presence & Indicators | 0/?            | Not started | -          |
| 8. Notifications         | 0/?            | Not started | -          |
| 9. Administration        | 0/?            | Not started | -          |
| 10. UI & PWA             | 0/?            | Not started | -          |
