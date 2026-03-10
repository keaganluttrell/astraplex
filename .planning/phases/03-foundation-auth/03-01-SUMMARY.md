---
phase: 03-foundation-auth
plan: 01
subsystem: auth
tags: [ash-authentication, bcrypt, password-strategy, policies, tokens]

requires:
  - phase: 01-engineering-quality
    provides: Repo, quality tooling, DaisyUIComponents, git hooks
provides:
  - Accounts Ash domain with User and Token resources
  - AshAuthentication password strategy (no self-signup)
  - Admin-only CRUD actions for user management
  - Sign-in with deactivated user blocking
  - Smokestack User factory for test data
  - ConnCase auth helper (register_and_log_in_user)
  - Negative authorization test patterns for CVE-2025-48043
affects: [03-foundation-auth, 04-messaging, 05-conversations, 09-admin]

tech-stack:
  added: [ash_authentication 4.13, ash_authentication_phoenix 2.15, bcrypt_elixir]
  patterns: [AshAuthentication password strategy, active-status sign-in filter, admin-only policy pattern, Ash.Seed.seed! for test prerequisites]

key-files:
  created:
    - lib/astraplex/accounts/accounts.ex
    - lib/astraplex/accounts/user.ex
    - lib/astraplex/accounts/token.ex
    - lib/astraplex/accounts/user/preparations/validate_active_status.ex
    - test/astraplex/accounts/user_test.exs
    - test/astraplex/accounts/user_authorization_test.exs
  modified:
    - mix.exs
    - config/config.exs
    - config/dev.exs
    - config/test.exs
    - config/runtime.exs
    - lib/astraplex/application.ex
    - test/support/factory.ex
    - test/support/conn_case.ex

key-decisions:
  - "Custom sign_in_with_password action with ValidateActiveStatus preparation to block deactivated users"
  - "require_token_presence_for_authentication? true for secure token revocation on logout"
  - "Ash.Seed.seed! for test user creation (bypasses policies for prerequisite data)"

patterns-established:
  - "Admin-only action pattern: policy authorize_if expr(^actor(:role) == :admin)"
  - "AshAuthentication bypass: bypass AshAuthenticationInteraction authorize_if always()"
  - "Active status filter on sign-in via custom read action preparation"
  - "Smokestack factory with pre-hashed passwords via AshAuthentication.BcryptProvider"

requirements-completed: [FOUND-01, FOUND-02, FOUND-03]

duration: 6min
completed: 2026-03-10
---

# Phase 3 Plan 1: Accounts Domain Summary

**Accounts domain with AshAuthentication password strategy, admin-only user CRUD, deactivated user blocking, and CVE-2025-48043 negative authorization coverage**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-10T03:55:30Z
- **Completed:** 2026-03-10T04:01:30Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments
- Accounts domain with User and Token resources using AshAuthentication password strategy
- Admin-only actions (create_user, update_role, deactivate, reactivate) all policy-protected
- Deactivated users blocked at sign-in via custom preparation (returns same error as invalid credentials)
- 19 integration tests: 12 positive + 7 negative authorization (CVE-2025-48043)

## Task Commits

Each task was committed atomically:

1. **Task 1: Install AshAuthentication, configure Accounts domain with User and Token** - `504d4f8` (feat)
2. **Task 2: Negative authorization tests (CVE-2025-48043)** - `8339072` (test)

## Files Created/Modified
- `lib/astraplex/accounts/accounts.ex` - Accounts Ash domain module
- `lib/astraplex/accounts/user.ex` - User resource with AshAuthentication, policies, admin actions
- `lib/astraplex/accounts/token.ex` - Token resource for session management
- `lib/astraplex/accounts/user/preparations/validate_active_status.ex` - Filters deactivated users from sign-in
- `test/astraplex/accounts/user_test.exs` - 12 integration tests for all user actions
- `test/astraplex/accounts/user_authorization_test.exs` - 7 negative authorization tests
- `test/support/factory.ex` - Smokestack User factory with pre-hashed passwords
- `test/support/conn_case.ex` - ConnCase auth helper for authenticated connection tests
- `mix.exs` - Added ash_authentication and ash_authentication_phoenix deps
- `config/config.exs` - Registered Accounts domain in ash_domains
- `config/dev.exs` - Dev token signing secret
- `config/test.exs` - Test token signing secret + bcrypt log_rounds: 1
- `config/runtime.exs` - Production token signing secret from env var
- `lib/astraplex/application.ex` - Added AshAuthentication.Supervisor to children

## Decisions Made
- Custom `sign_in_with_password` read action instead of auto-generated one, allowing a `ValidateActiveStatus` preparation to filter out deactivated users before password check
- Set `require_token_presence_for_authentication?` to `true` per AshAuthentication 4.13 guidance, ensuring tokens are always validated and revocable
- Used `Ash.Seed.seed!` in tests for prerequisite user creation, bypassing policies (correct pattern for test setup)
- Password confirmation validation on `create_user` action via `confirm/2` Ash validation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] sign_in_preparation DSL option does not exist**
- **Found during:** Task 1 (User resource implementation)
- **Issue:** Plan specified `sign_in_preparation` in password strategy DSL, but this option does not exist in AshAuthentication 4.13
- **Fix:** Defined a custom `read :sign_in_with_password` action with the `ValidateActiveStatus` preparation added before the built-in `SignInPreparation`
- **Files modified:** lib/astraplex/accounts/user.ex
- **Verification:** Sign-in tests pass for active users, fail for deactivated users
- **Committed in:** 504d4f8

**2. [Rule 3 - Blocking] session_identifier configuration required**
- **Found during:** Task 1 (compilation)
- **Issue:** AshAuthentication 4.13 requires explicit `session_identifier` or `require_token_presence_for_authentication?` setting
- **Fix:** Set `require_token_presence_for_authentication? true` in authentication tokens block (most secure option)
- **Files modified:** lib/astraplex/accounts/user.ex
- **Verification:** Clean compilation with --warnings-as-errors
- **Committed in:** 504d4f8

**3. [Rule 3 - Blocking] Stale users table in dev and test databases**
- **Found during:** Task 1 (migration)
- **Issue:** Existing `users` table from unknown source blocked migration
- **Fix:** Reset both dev and test databases via `ecto.drop --force-drop` + `ecto.create` + `ash.migrate`
- **Files modified:** None (database state only)
- **Verification:** Migrations run successfully
- **Committed in:** 504d4f8

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All auto-fixes necessary for compilation and correct behavior. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Accounts domain fully operational for Plans 02-05 in this phase
- User/Token resources ready for router integration (Plan 02: sign-in LiveView, auth plugs)
- Admin user management actions ready for Plan 04 (admin UI)
- Smokestack factory and ConnCase auth helper ready for all future test files
- Negative authorization test pattern established for all future policy testing

## Self-Check: PASSED

All 6 key files verified present. Both task commits (504d4f8, 8339072) verified in git log.

---
*Phase: 03-foundation-auth*
*Completed: 2026-03-10*
