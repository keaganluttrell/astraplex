# Phase 1: Engineering Quality - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Project scaffold with enforced code quality, a test harness ready for integration and E2E tests, and a design system for consistent UI. Covers QUAL-01 through QUAL-08: integration test suite, E2E test suite, static analysis, git hooks (pre-commit and pre-push), CLAUDE.md conventions, and design system bootstrap.

</domain>

<decisions>
## Implementation Decisions

### Design System
- Use daisyUI (ships with Phoenix 1.8+) with DaisyUIComponents library for LiveView-native components
- Light/corporate theme direction — clean white backgrounds, subtle grays, professional feel (like Linear/Notion/Slack light mode)
- Stock daisyUI theme (no custom brand colors) — can customize later
- Core primitives only in Phase 1: Button, Input, Badge, Avatar, Card, Modal — enough to build auth screens in Phase 3
- Expand component library as needed in later phases

### CLAUDE.md Conventions
- Conventional Commits with domain-scoped types: `feat(messaging):`, `fix(auth):`, `test(accounts):`, etc.
- Scopes match Ash domains (accounts, messaging, notifications) plus infra, deps, docs, test
- Strict guardrails — hard rules, not guidelines:
  - NEVER use raw Ecto queries — ALL data access through Ash actions
  - Domains MUST NOT reach into other domains' internals
  - Resources live in their domain directory
  - Policies on EVERY action
  - Integration test for every action
  - No business logic in LiveView
- Explicit file conventions:
  - Module structure order: @moduledoc, use/import/alias, @attributes, Ash resource DSL blocks, public functions, private functions
  - No modules over ~300 lines
  - Group related functions
  - @doc on public functions
  - Typespec on public API functions
- Thin LiveViews (target <150 lines):
  - LiveView handles: mount/handle_params, handle_event (delegates to Ash), render (composes components)
  - LiveView does NOT: query database directly, contain business rules, do complex data transforms
  - Function components preferred, use slots for flexibility

### Testing Tools
- E2E testing tool: let research decide (evaluate Wallaby vs Playwright vs alternatives for LiveView compatibility)
- Static analysis strictness: let research decide (evaluate Credo config levels and Dialyzer alternatives)
- Test factories: Ash actions + Smokestack (Ash-native factory library) — test setup goes through real Ash actions where fidelity matters, Smokestack for convenience with bulk data
- No ExMachina — it bypasses Ash and inserts directly via Ecto

### Git Hooks
- Pre-commit blocks on: format check (`mix format --check-formatted`), compilation (`mix compile --warnings-as-errors`), static analysis (Credo/Dialyzer)
- Pre-push blocks on: full test suite (`mix test`) — E2E tests are CI-only, not in hooks
- Warnings-as-errors: yes, zero tolerance — unused variables, unused imports, deprecation warnings all block commits
- No bypass allowed — hooks always enforced, no `--no-verify`

### Claude's Discretion
- E2E tool selection (after research evaluates options)
- Static analysis tool configuration and strictness level (after research)
- Specific daisyUI theme choice between 'corporate' and 'light'
- Loading skeleton and error state patterns for design system
- Exact Smokestack configuration and helper module structure
- Git hook implementation approach (lefthook, husky, custom scripts)

</decisions>

<specifics>
## Specific Ideas

- Design system should feel like Linear/Notion/Slack light mode — muted colors, subtle borders, lots of whitespace
- User instinct to use Ash-native tools over external libraries (Smokestack over ExMachina, Ash actions over raw Ecto)
- This is the first vertical / architectural blueprint — patterns established here will be reused across future domains

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing codebase — this is a greenfield project
- Phoenix 1.8+ ships with Tailwind and daisyUI configured out of the box

### Established Patterns
- No existing patterns — this phase establishes them

### Integration Points
- CLAUDE.md will be read by Claude in all future phases
- Design system components will be used starting in Phase 3 (auth screens)
- Test harness and factories will be used in all subsequent phases
- Git hooks will enforce quality on all future commits

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-engineering-quality*
*Context gathered: 2026-03-09*
