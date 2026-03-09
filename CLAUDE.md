# Astraplex - Project Conventions

Rules in this file are STRICT. Violations are bugs. Claude MUST follow these in every session.

## Project Overview

Astraplex is a real-time internal messaging platform for staff and admins.

- **Stack:** Elixir 1.18, Phoenix 1.8, Ash Framework 3.x, LiveView, PostgreSQL
- **Design:** daisyUI 5 with DaisyUIComponents, corporate theme (`data-theme="corporate"`)
- **Architecture:** Domain-driven via Ash Framework with strict resource boundaries

## Commit Conventions

Use Conventional Commits: `type(scope): description`

**Types:** feat, fix, refactor, test, docs, chore, style, perf, ci

**Scopes match Ash domains:**
- accounts, messaging, notifications, presence, admin

**Infrastructure scopes:**
- infra, deps, docs, test, ui

**Examples:**
```
feat(messaging): add message threading
fix(auth): handle expired session redirect
test(accounts): add policy tests for user creation
refactor(notifications): extract delivery strategy
```

## Architecture Rules (STRICT)

- NEVER use raw Ecto queries -- ALL data access through Ash actions
- Domains MUST NOT reach into other domains' internals
- Resources live in their domain directory (e.g., `lib/astraplex/accounts/user.ex`)
- Policies on EVERY Ash action -- no exceptions
- Integration test for every Ash action
- No business logic in LiveView modules

## File Conventions

**Module structure order:**
1. `@moduledoc`
2. `use` / `import` / `alias`
3. `@attributes`
4. Ash resource DSL blocks
5. Public functions
6. Private functions

**Rules:**
- No modules over ~300 lines -- split if approaching
- Group related functions together
- `@doc` on all public functions
- `@spec` on public API functions (functions called from outside the module)

## LiveView Rules

**Target:** <150 lines per LiveView module

**LiveView handles:**
- `mount` / `handle_params`
- `handle_event` (delegates to Ash actions)
- `render` (composes function components)

**LiveView does NOT:**
- Query database directly
- Contain business rules
- Do complex data transforms

**Component rules:**
- Function components preferred, use slots for flexibility
- All data fetching through Ash actions, NEVER Repo calls

## Testing Rules

- Integration tests for every Ash action (covers policies, validations, calculations)
- No unit tests (integration and E2E provide more value for domain-driven Ash architecture)
- Use Smokestack factories for prerequisite/bulk data setup
- Use Ash actions directly for the behavior being tested
- NEVER use raw Ecto (`Repo.insert!`) in tests -- always Smokestack or Ash actions
- NEVER use ExMachina
- E2E tests tagged with `@moduletag :e2e`, excluded by default, CI runs with `--include e2e`

## Design System

- Use DaisyUIComponents for all UI components
- Corporate daisyUI theme (`data-theme="corporate"`)
- Tailwind CSS 4 utility classes for layout/spacing
- No custom CSS unless absolutely necessary

## Development Commands

```bash
mix test                    # Run integration tests (excludes E2E)
mix test --include e2e      # Run all tests including E2E
mix credo --strict          # Static analysis
mix dialyzer                # Type checking
mix format                  # Format code
mix format --check-formatted # Check formatting
```

## Domain Structure

```
lib/astraplex/               # Ash domains and resources
  accounts/                  # User management, auth
  messaging/                 # Messages, channels, conversations
  notifications/             # Notification delivery
lib/astraplex_web/           # Web layer
  components/                # Design system, function components
  live/                      # LiveView modules
  layouts/                   # Layout templates
```

## Security

- Ash policy CVE (CVE-2025-48043) identified -- negative authorization tests required from Phase 3 onward
- No bypass mechanism for git hooks -- hooks always enforced
- Zero tolerance for compiler warnings (`--warnings-as-errors`)
