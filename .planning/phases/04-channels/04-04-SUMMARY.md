---
phase: 04-channels
plan: 04
subsystem: messaging
tags: [archived-channels, sidebar, navigation, ash-query]

# Dependency graph
requires:
  - phase: 04-channels
    provides: Channel resource, chat view, sidebar integration, archive action
provides:
  - Archived channel access via sidebar and admin table View link
  - Visual distinction for archived channels in sidebar (opacity-50)
  - list_for_user returns both active and archived channels
affects: [05-conversations]

# Tech tracking
tech-stack:
  added: []
  patterns: [archived-resource-access-pattern]

key-files:
  created: []
  modified:
    - lib/astraplex/messaging/channel.ex
    - lib/astraplex_web/components/layouts.ex
    - lib/astraplex_web/live/admin/channel_list_live.ex
    - lib/astraplex_web/live/channel_live.ex
    - test/astraplex/messaging/channel_test.exs

key-decisions:
  - "list_for_user broadened to status in [:active, :archived] for archived channel sidebar access"
  - "opacity-50 CSS class for archived channel visual distinction in sidebar"

patterns-established:
  - "Archived resource access: include archived items in list queries, distinguish visually with opacity"

requirements-completed: []

# Metrics
duration: 5min
completed: 2026-03-10
---

# Phase 04 Plan 04: Gap Closure - Archived Channel Access Summary

**Broadened list_for_user to include archived channels with sidebar visual distinction and admin table View link**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-10T22:01:45Z
- **Completed:** 2026-03-10T22:07:28Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Archived channels now appear in sidebar for all members with reduced opacity
- Admin channel table has View (eye) icon linking directly to channel chat view
- Existing archived channel UI (warning banner, disabled input) accessible without workarounds
- All 106 tests pass with updated assertions

## Task Commits

Each task was committed atomically:

1. **Task 1: Add archived channel navigation paths** - `4e2c22a` (fix)
2. **Task 2: Verify archived channel access** - checkpoint:human-verify (approved)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `lib/astraplex/messaging/channel.ex` - Broadened list_for_user filter to include archived status
- `lib/astraplex_web/components/layouts.ex` - Added opacity-50 for archived sidebar items
- `lib/astraplex_web/live/admin/channel_list_live.ex` - Added View link, archived flag in sidebar data
- `lib/astraplex_web/live/channel_live.ex` - Added archived flag in sidebar channel maps
- `test/astraplex/messaging/channel_test.exs` - Updated test to assert archived channels included

## Decisions Made
- Broadened `list_for_user` filter from `status == :active` to `status in [:active, :archived]` so archived channels appear in sidebar
- Used `opacity-50` CSS class on sidebar items with `archived: true` flag for visual distinction
- Added eye icon View link in admin table alongside existing gear icon for direct chat navigation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated existing test assertion for new list_for_user behavior**
- **Found during:** Task 1
- **Issue:** Existing test "excludes archived channels" asserted `channels == []` which contradicts the new intended behavior
- **Fix:** Renamed test to "includes archived channels for member access" and updated assertions to verify archived channels are returned with correct status
- **Files modified:** test/astraplex/messaging/channel_test.exs
- **Verification:** All 106 tests pass
- **Committed in:** 4e2c22a (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Test update was necessary to match the intentional behavior change. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 04 (Channels) is now fully complete with all gap closures addressed
- Ready for Phase 05 (Conversations / DMs and Group Messages)

---
*Phase: 04-channels*
*Completed: 2026-03-10*
