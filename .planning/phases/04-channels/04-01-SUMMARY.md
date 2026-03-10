---
phase: 04-channels
plan: 01
subsystem: messaging
tags: [ash, channels, membership, messages, pubsub, policies, authorization]

requires:
  - phase: 03-foundation
    provides: User resource with roles (admin/staff), AshAuthentication, Smokestack factories
provides:
  - Messaging Ash domain with Channel, Membership, Message resources
  - Channel CRUD actions with admin-only policies
  - Membership join resource with unique constraint
  - Message send_message action with membership and archived channel checks
  - PubSub notifiers on Membership and Message for real-time updates
  - Custom CanSendToChannel policy check for create action authorization
  - Smokestack factories for all messaging resources
  - 23 integration tests including negative authorization tests (CVE-2025-48043)
affects: [04-02, 04-03, 05-conversations, 06-messaging-core, 07-presence]

tech-stack:
  added: []
  patterns: [custom-policy-check-for-create-actions, membership-based-authorization, pubsub-notifier-config]

key-files:
  created:
    - lib/astraplex/messaging/messaging.ex
    - lib/astraplex/messaging/channel.ex
    - lib/astraplex/messaging/membership.ex
    - lib/astraplex/messaging/message.ex
    - lib/astraplex/messaging/checks/can_send_to_channel.ex
    - test/astraplex/messaging/channel_test.exs
    - test/astraplex/messaging/channel_authorization_test.exs
    - test/astraplex/messaging/membership_test.exs
    - test/astraplex/messaging/membership_authorization_test.exs
    - test/astraplex/messaging/message_test.exs
    - test/astraplex/messaging/message_authorization_test.exs
  modified:
    - config/config.exs
    - test/support/factory.ex

key-decisions:
  - "Custom SimpleCheck for Message send_message policy -- Ash expressions cannot filter create actions that reference relationships"
  - "Channel and Membership create actions marked as primary? true for Ash.create! convenience"
  - "Message channel_id marked public? true to allow accept in send_message action"
  - "conversation_id NOT added to Message yet per plan -- Phase 5 adds it with Conversation resource"

patterns-established:
  - "Custom policy check pattern: use Ash.Policy.SimpleCheck with Ash.Query.filter for create action authorization that needs relationship data"
  - "Membership-based read policies: expr(exists(channel.memberships, user_id == ^actor(:id))) for resource scoping"
  - "PubSub notifier pattern: pub_sub block with module AstraplexWeb.Endpoint and topic templates"

requirements-completed: [CHAN-01, CHAN-02, CHAN-03, CHAN-04, CHAN-05, CHAN-06]

duration: 6min
completed: 2026-03-10
---

# Phase 4 Plan 1: Messaging Domain Summary

**Messaging domain with Channel, Membership, Message Ash resources, admin-only management policies, membership-based read authorization, and 23 integration tests including negative auth**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-10T20:03:45Z
- **Completed:** 2026-03-10T20:09:55Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments
- Complete Messaging Ash domain with three resources (Channel, Membership, Message)
- All six CHAN requirements covered at the action/policy layer
- 23 integration tests including 10 negative authorization tests (CVE-2025-48043 compliance)
- PubSub notifiers configured for real-time message and membership change broadcasting

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Messaging domain, Channel, Membership, and Message resources** - `de7d354` (feat)
2. **Task 2: Integration tests with negative auth** - `c5214b1` (test)

## Files Created/Modified
- `lib/astraplex/messaging/messaging.ex` - Messaging Ash domain module
- `lib/astraplex/messaging/channel.ex` - Channel resource with CRUD actions and policies
- `lib/astraplex/messaging/membership.ex` - Membership join resource with unique constraint
- `lib/astraplex/messaging/message.ex` - Message resource with send_message and read policies
- `lib/astraplex/messaging/checks/can_send_to_channel.ex` - Custom policy check for create action
- `config/config.exs` - Registered Astraplex.Messaging domain
- `test/support/factory.ex` - Added Channel, Membership, Message Smokestack factories
- `test/astraplex/messaging/channel_test.exs` - Channel action integration tests (6 tests)
- `test/astraplex/messaging/channel_authorization_test.exs` - Channel negative auth tests (4 tests)
- `test/astraplex/messaging/membership_test.exs` - Membership action tests (3 tests)
- `test/astraplex/messaging/membership_authorization_test.exs` - Membership negative auth tests (4 tests)
- `test/astraplex/messaging/message_test.exs` - Message action tests (4 tests)
- `test/astraplex/messaging/message_authorization_test.exs` - Message negative auth tests (2 tests)

## Decisions Made
- **Custom SimpleCheck for send_message policy:** Ash expressions that reference relationships (exists/relates_to_actor_via) cannot be used on create actions because the record doesn't exist yet. Created CanSendToChannel custom check that queries membership and channel status directly.
- **primary? true on create actions:** Channel and Membership create actions marked as primary so Ash.create! works without explicit action: option.
- **Message channel_id public? true:** belongs_to relationship attributes are not public by default in Ash 3.x. Made channel_id public so it can be accepted in send_message action.
- **Deferred conversation_id:** Per plan guidance, conversation_id column NOT added to Message yet. Phase 5 adds it alongside the Conversation resource to avoid compilation issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ash validation :on option only accepts action types, not action names**
- **Found during:** Task 1 (Resource creation)
- **Issue:** `validate present(:channel_id), on: [:send_message]` failed because :on only accepts action types (:create, :update, etc.)
- **Fix:** Moved validation inside the send_message action block as inline validation
- **Files modified:** lib/astraplex/messaging/message.ex
- **Verification:** Compilation passes
- **Committed in:** de7d354

**2. [Rule 1 - Bug] Ash expressions cannot filter create actions that reference relationships**
- **Found during:** Task 2 (Tests revealed Forbidden error for members)
- **Issue:** Policy `expr(exists(channel.memberships, user_id == ^actor(:id)) and channel.status != :archived)` on send_message (a create action) raised "Cannot use a filter to authorize a create"
- **Fix:** Created custom Ash.Policy.SimpleCheck (CanSendToChannel) that queries channel and membership directly
- **Files modified:** lib/astraplex/messaging/checks/can_send_to_channel.ex, lib/astraplex/messaging/message.ex
- **Verification:** All 23 tests pass
- **Committed in:** c5214b1

**3. [Rule 1 - Bug] Smokestack insert! API requires attrs: keyword, not bare map**
- **Found during:** Task 2 (Tests failed with FunctionClauseError)
- **Issue:** `Factory.insert!(User, %{role: :admin})` incorrect -- Smokestack expects `attrs: %{role: :admin}`
- **Fix:** Updated all test files to use `attrs:` keyword option
- **Files modified:** All 6 test files
- **Verification:** All tests pass
- **Committed in:** c5214b1

**4. [Rule 1 - Bug] Named create actions not set as primary**
- **Found during:** Task 2 (Tests failed with "Required primary create action")
- **Issue:** `Ash.create!(Channel, %{...}, actor: admin)` requires a primary create action; named :create actions are not primary by default
- **Fix:** Added `primary?(true)` to Channel and Membership create actions
- **Files modified:** lib/astraplex/messaging/channel.ex, lib/astraplex/messaging/membership.ex
- **Verification:** All tests pass
- **Committed in:** c5214b1

---

**Total deviations:** 4 auto-fixed (4 bugs via Rule 1)
**Impact on plan:** All fixes necessary for correctness. Custom policy check is the key architectural discovery -- create actions in Ash cannot use relationship-based expressions in policies. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Messaging domain fully operational with all CRUD actions and policies
- PubSub notifiers ready for LiveView real-time integration (Plan 04-02/04-03)
- Factories available for UI integration tests
- Custom check pattern established for future create-action policies

---
*Phase: 04-channels*
*Completed: 2026-03-10*
