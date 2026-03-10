---
phase: 03-foundation-auth
plan: 02
subsystem: auth
tags: [ash-authentication-phoenix, liveview, router, sign-in, session, on-mount]

requires:
  - phase: 03-foundation-auth
    provides: Accounts domain with User, Token, AshAuthentication password strategy
  - phase: 01-engineering-quality
    provides: DaisyUIComponents, Repo, git hooks
provides:
  - Custom sign-in LiveView with centered card aesthetic
  - Auth-aware router with authenticated, admin, and public scopes
  - LiveAuth on_mount hooks for route protection
  - AuthController for sign-out and auth callbacks
  - Placeholder dashboard with user email and sign-out link
  - Admin user list placeholder LiveView
affects: [03-foundation-auth, 04-messaging, 05-conversations, 09-admin]

tech-stack:
  added: []
  patterns: [AshPhoenix.Form for sign-in, phx-trigger-action POST pattern, ash_authentication_live_session, LiveAuth on_mount hooks]

key-files:
  created:
    - lib/astraplex_web/controllers/auth_controller.ex
    - lib/astraplex_web/live/live_auth.ex
    - lib/astraplex_web/live/auth_live/sign_in_live.ex
    - lib/astraplex_web/live/dashboard_live.ex
    - lib/astraplex_web/live/admin/user_list_live.ex
    - test/astraplex_web/live/auth_live_test.exs
  modified:
    - lib/astraplex_web/router.ex
    - lib/astraplex/accounts/user.ex

key-decisions:
  - "store_all_tokens? true required alongside require_token_presence_for_authentication? for token DB lookup"
  - "async: false for LiveView auth tests to ensure Ecto sandbox access across processes"
  - "phx-trigger-action pattern: LiveView validates then triggers standard form POST for actual authentication"

patterns-established:
  - "LiveAuth on_mount pattern: check socket.assigns[:current_user] with struct matching for status/role"
  - "ash_authentication_live_session wrapping scope for authenticated LiveView routes"
  - "AshPhoenix.Form.for_action for sign-in with to_form conversion"
  - "Generic error display: show 'Invalid email or password' based on form.source.errors presence"

requirements-completed: [FOUND-04, FOUND-05, FOUND-06]

duration: 11min
completed: 2026-03-10
---

# Phase 3 Plan 2: Auth Web Layer Summary

**Custom sign-in LiveView with AshPhoenix.Form, auth-aware router with LiveAuth on_mount hooks, and session-persistent authentication flow**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-10T04:05:10Z
- **Completed:** 2026-03-10T04:16:25Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Custom sign-in page with centered card layout, Astraplex title, email/password fields, and DaisyUIComponents
- Router restructured with three auth scopes: public (sign-in, auth callbacks), authenticated (dashboard), admin (user management)
- LiveAuth on_mount hooks enforcing authentication and admin role checks with active status verification
- Session persistence via load_from_session plug + store_all_tokens for database-backed token validation
- 8 integration tests covering routing, sign-in rendering, error display, dashboard access, admin access control

## Task Commits

Each task was committed atomically:

1. **Task 1: Auth controller, LiveAuth hooks, and router** - `d9c39ab` (test: RED), `71a6218` (feat: GREEN)
2. **Task 2: Custom sign-in LiveView and dashboard** - `f88cbce` (feat)

## Files Created/Modified
- `lib/astraplex_web/controllers/auth_controller.ex` - Sign-out, success/failure callbacks using AshAuthentication.Phoenix.Controller
- `lib/astraplex_web/live/live_auth.ex` - on_mount hooks: require_authenticated_user, require_admin, redirect_if_authenticated
- `lib/astraplex_web/live/auth_live/sign_in_live.ex` - Centered card sign-in with AshPhoenix.Form and phx-trigger-action
- `lib/astraplex_web/live/dashboard_live.ex` - Post-login placeholder with user email and sign-out link
- `lib/astraplex_web/live/admin/user_list_live.ex` - Admin user management placeholder
- `lib/astraplex_web/router.ex` - Auth-aware routing with load_from_session, ash_authentication_live_session
- `lib/astraplex/accounts/user.ex` - Added store_all_tokens? true to authentication tokens block
- `test/astraplex_web/live/auth_live_test.exs` - 8 integration tests for auth flow

## Decisions Made
- Added `store_all_tokens? true` to User resource -- required for `require_token_presence_for_authentication?` to work, since `authenticate_resource_from_session` checks the token exists in the database
- Used `async: false` for LiveView auth tests because LiveView WebSocket mounts run in endpoint processes that need shared Ecto sandbox access
- Chose phx-trigger-action pattern (LiveView validates, then triggers standard form POST) per AshAuthentication Phoenix conventions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] store_all_tokens? required for token presence authentication**
- **Found during:** Task 1 (router + auth flow testing)
- **Issue:** `require_token_presence_for_authentication?` was set to true but `store_all_tokens?` was false (default). The `authenticate_resource_from_session` function checks the token exists in the database via `get_token`, but tokens were never stored because `store_all_tokens?` controls token persistence.
- **Fix:** Added `store_all_tokens?(true)` to User resource authentication tokens block
- **Files modified:** lib/astraplex/accounts/user.ex
- **Verification:** Authentication flow works end-to-end, all tests pass
- **Committed in:** 71a6218

**2. [Rule 3 - Blocking] Removed obsolete PageController test**
- **Found during:** Task 1 (full suite run)
- **Issue:** Old `PageControllerTest` expected `GET /` to return the Phoenix welcome page, but `/` now routes to authenticated DashboardLive
- **Fix:** Deleted test/astraplex_web/controllers/page_controller_test.exs (behavior now covered by auth_live_test.exs)
- **Files modified:** test/astraplex_web/controllers/page_controller_test.exs (deleted)
- **Verification:** Full test suite passes
- **Committed in:** 71a6218

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary for correct authentication flow. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Full sign-in/sign-out flow operational for all future development
- LiveAuth hooks ready for any new authenticated or admin LiveViews
- Router structure ready for Plans 03-05 (mix tasks, admin UI, seeds)
- DaisyUIComponents form patterns established for admin user creation form
- Placeholder admin LiveView ready for Plan 04 expansion

## Self-Check: PASSED

All 6 key files verified present. All 3 task commits (d9c39ab, 71a6218, f88cbce) verified in git log.

---
*Phase: 03-foundation-auth*
*Completed: 2026-03-10*
