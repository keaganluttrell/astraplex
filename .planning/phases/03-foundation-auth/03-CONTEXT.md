# Phase 3: Foundation & Auth - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin-created user accounts with two roles (Admin/Staff), email/password authentication, and persistent session management. Covers FOUND-01 through FOUND-06: account creation, role assignment, account deactivation, login, session persistence, and logout. No self-signup. Admin UI for user management is a basic page that Phase 9 will refine into a full admin dashboard.

</domain>

<decisions>
## Implementation Decisions

### Admin Bootstrapping
- First admin created via `mix astraplex.create_admin` mix task (email + password as args, no defaults)
- Admin sets the real password during bootstrap — no forced password change flow
- Multiple admins allowed — any admin can create other admin accounts, no limit
- Dev seeds (seeds.exs) create sample users for local development: 1 admin + several staff with known credentials
- Mix task for production/staging, seeds for dev convenience

### Login Experience
- Centered card layout on neutral background — matches the clean Linear/Notion aesthetic from Phase 1
- Email + password fields, login button, app name ("Astraplex") above the card
- No logo, tagline, or additional branding — app name text only
- Generic error on failure: "Invalid email or password" — never reveals whether an email exists
- After successful login, user lands on a dashboard/home page (placeholder for Phase 4+ channel views)

### Deactivation Behavior
- Deactivated users see same generic "Invalid email or password" on login attempt — consistent with login error approach
- Deactivated users appear in admin user lists with a visible "Deactivated" status badge — admin can filter by status
- Deactivation is reversible — admin can reactivate accounts (practical for staff who leave and return)
- Active sessions terminated immediately on deactivation (user logged out on next request)
- Deactivated user's display name stays as-is in existing messages — no "(deactivated)" tag
- Modal confirmation before deactivation: "Are you sure you want to deactivate [Name]? They will be logged out immediately."
- No reason field for deactivation — keep it simple, Phase 9 adds audit logging
- Reactivated accounts keep original password — no forced password reset

### User Management Flow
- Single form for user creation: email, password, role (Admin/Staff dropdown) — submit creates immediately
- Admin sets the user's password (communicated out-of-band: verbally, Slack, etc.) — no email invite flow
- Roles changeable anytime after creation — admin can promote Staff to Admin or demote Admin to Staff
- User management lives at a simple /admin/users LiveView page with user list table and create button
- Phase 9 will refine this into the full admin dashboard

### Claude's Discretion
- Auth library choice (AshAuthentication vs custom — researcher evaluates)
- Password hashing algorithm (bcrypt vs argon2)
- Session storage strategy (cookie vs database-backed)
- Exact dashboard/home page content for post-login landing
- Table design and pagination for admin user list
- MCP endpoint auth (deferred from Phase 2 — decide if Phase 3 addresses or defers further)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- DaisyUIComponents with corporate theme available for all UI (card, form inputs, button, modal, badge)
- System domain (lib/astraplex/system/) as reference for Ash domain structure
- Router has browser pipeline with session, CSRF, and root layout already configured
- Mailer module exists (lib/astraplex/mailer.ex) — available if email needed later

### Established Patterns
- Ash-native tools preferred (Smokestack factories, Ash actions for all data access)
- Domain directory convention: lib/astraplex/{domain}/{resource}.ex
- Policies required on every Ash action (CLAUDE.md rule)
- Integration test for every Ash action (CLAUDE.md rule)
- No raw Ecto queries — all data through Ash actions

### Integration Points
- Router (lib/astraplex_web/router.ex) — needs auth plugs, login routes, admin routes
- Endpoint (lib/astraplex_web/endpoint.ex) — has SQL sandbox plug for E2E tests
- MCP scope at /mcp — currently no auth (Phase 2 deferred this)
- Accounts domain will be auto-discovered by MCP server (Phase 2 decision)
- Smokestack factories in test/support/ for user factories

</code_context>

<specifics>
## Specific Ideas

- Consistent security posture: never reveal account existence through any error message (login failure, deactivated accounts)
- CVE-2025-48043: negative authorization tests required — test that Staff CANNOT access admin routes, deactivated users CANNOT log in
- First admin bootstrap must work in CI/deploy pipelines (mix task, not interactive)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-foundation-auth*
*Context gathered: 2026-03-09*
