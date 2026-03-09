---
phase: 01-engineering-quality
plan: 01
subsystem: infra
tags: [phoenix, ash, ash_postgres, smokestack, elixir, ecto, test-harness]

# Dependency graph
requires: []
provides:
  - Phoenix 1.8 project scaffold with Ash 3.x integration
  - AshPostgres Repo with uuid-ossp, citext, ash-functions extensions
  - Smokestack factory module ready for resource definitions
  - DataCase and ConnCase with factory imports and Ecto sandbox
  - Test harness with ExUnit configured for Ash (disable_async, missed_notifications)
  - All Phase 1 dependencies installed (Credo, Dialyxir, DaisyUIComponents, PhoenixTestPlaywright, git_hooks)
affects: [01-engineering-quality, 02-ai-tooling, 03-foundation-auth]

# Tech tracking
tech-stack:
  added: [phoenix 1.8.5, ash 3.19.3, ash_postgres 2.8.0, ash_phoenix 2.3.20, daisy_ui_components 0.9.3, credo 1.7.17, dialyxir 1.4.7, smokestack 0.9.2, faker 0.18.0, phoenix_test_playwright 0.13.0, git_hooks 0.8.1]
  patterns: [AshPostgres.Repo with extensions, Smokestack factory module, DataCase/ConnCase with factory import, ExUnit e2e tag exclusion]

key-files:
  created: [mix.exs, lib/astraplex/repo.ex, test/support/factory.ex, test/astraplex/smoke_test.exs, config/config.exs, config/test.exs, config/dev.exs, config/runtime.exs]
  modified: [test/support/data_case.ex, test/support/conn_case.ex, test/test_helper.exs]

key-decisions:
  - "Used AshPostgres.Repo instead of Ecto.Repo for Ash integration"
  - "Added ash-functions extension and min_pg_version to Repo to eliminate compilation warnings"
  - "Set server: true in test.exs for E2E test readiness (PhoenixTestPlaywright requires real HTTP server)"

patterns-established:
  - "AshPostgres.Repo pattern: installed_extensions with uuid-ossp, citext, ash-functions plus min_pg_version"
  - "Test factory pattern: single Smokestack factory module imported in DataCase and ConnCase"
  - "E2E exclusion pattern: ExUnit.configure(exclude: [:e2e]) in test_helper.exs"

requirements-completed: [QUAL-01, QUAL-06]

# Metrics
duration: 5min
completed: 2026-03-09
---

# Phase 1 Plan 1: Project Scaffold and Test Harness Summary

**Phoenix 1.8 / Ash 3.x project scaffold with Smokestack test factory harness and all Phase 1 dependencies installed**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-09T23:39:04Z
- **Completed:** 2026-03-09T23:43:42Z
- **Tasks:** 2
- **Files modified:** 49

## Accomplishments
- Scaffolded a complete Phoenix 1.8 / Ash 3.x application that compiles cleanly with zero warnings
- Installed all Phase 1 dependencies (Ash ecosystem, quality tools, test infra, design system, git hooks)
- Configured Smokestack factory module with DataCase/ConnCase integration and Ash test settings
- All 7 tests passing (5 Phoenix scaffold + 2 harness smoke tests)

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold Phoenix/Ash project and install all Phase 1 dependencies** - `1fdad63` (feat)
2. **Task 2: Configure test harness with Smokestack factories and Ash test helpers** - `ebdb5a6` (feat)

## Files Created/Modified
- `mix.exs` - Project definition with all Phase 1 deps (Ash, DaisyUI, Credo, Dialyxir, Smokestack, etc.)
- `lib/astraplex/repo.ex` - AshPostgres.Repo with uuid-ossp, citext, ash-functions extensions
- `config/config.exs` - Ash domains config, default_belongs_to_type
- `config/test.exs` - Ash test config (disable_async, missed_notifications), PhoenixTest, server: true
- `config/dev.exs` - Development database and endpoint config
- `config/runtime.exs` - Production runtime config
- `test/support/factory.ex` - Smokestack factory module (empty, ready for resources)
- `test/support/data_case.ex` - DataCase with factory import and Ecto sandbox
- `test/support/conn_case.ex` - ConnCase with factory import and auth helper placeholder
- `test/test_helper.exs` - ExUnit with e2e exclusion and sandbox manual mode
- `test/astraplex/smoke_test.exs` - Smoke tests for harness and factory availability

## Decisions Made
- Used AshPostgres.Repo instead of Ecto.Repo -- required for Ash integration with Postgres
- Added ash-functions extension to Repo -- eliminates compilation warnings and enables Ash atomics, string_trim, and boolean operators
- Added min_pg_version to Repo -- eliminates deprecation warning, set to PG 16 (running PG 17)
- Set server: true in test.exs -- PhoenixTestPlaywright requires a real HTTP server for E2E tests (Plan 02)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added ash-functions extension and min_pg_version to Repo**
- **Found during:** Task 1
- **Issue:** Compilation produced warnings about missing ash-functions extension (disabling atomics, string_trim, boolean operators) and missing min_pg_version/0 callback
- **Fix:** Added "ash-functions" to installed_extensions and defined min_pg_version returning %Version{major: 16, minor: 0, patch: 0}
- **Files modified:** lib/astraplex/repo.ex
- **Verification:** mix compile --warnings-as-errors passes cleanly
- **Committed in:** 1fdad63 (part of Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential for clean compilation with --warnings-as-errors. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phoenix/Ash scaffold complete with all Phase 1 deps installed
- Test harness operational with Smokestack factories and Ash test config
- Ready for Plan 02: E2E browser testing (PhoenixTestPlaywright) and DaisyUIComponents design system
- Ready for Plan 03: Static analysis (Credo/Dialyxir), git hooks, and CLAUDE.md conventions

## Self-Check: PASSED

All 9 key files verified present. Both task commits (1fdad63, ebdb5a6) verified in git log.

---
*Phase: 01-engineering-quality*
*Completed: 2026-03-09*
