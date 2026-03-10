---
phase: 02-ai-tooling
plan: 01
subsystem: infra
tags: [ash_ai, mcp, phoenix, health-check, dev-tooling]

# Dependency graph
requires:
  - phase: 01-engineering-quality
    provides: "Phoenix endpoint, Ash framework setup, pre-commit hooks"
provides:
  - "System domain with Health resource for operational diagnostics"
  - "MCP dev server at /ash_ai/mcp for AI agent tool discovery"
  - ".mcp.json for Claude Code MCP auto-connection"
  - "AshAi extension pattern for future domains"
affects: [02-ai-tooling, 03-foundation, messaging, accounts]

# Tech tracking
tech-stack:
  added: [ash_ai, mcp-remote]
  patterns: [ash-ai-domain-extension, mcp-dev-server, embedded-resource-generic-action]

key-files:
  created:
    - lib/astraplex/system/system.ex
    - lib/astraplex/system/health.ex
    - test/astraplex/system/health_test.exs
    - .mcp.json
  modified:
    - mix.exs
    - mix.lock
    - config/config.exs
    - config/runtime.exs
    - lib/astraplex_web/endpoint.ex

key-decisions:
  - "Used mcp-remote npx command transport instead of direct HTTP type for Claude Code compatibility"
  - "AshAi.Mcp.Dev only exposes introspection tools (list_ash_resources, get_usage_rules, list_generators) -- domain tools need separate production MCP router (Plan 02-02)"
  - "Health resource uses embedded data layer with generic action -- no database needed"
  - "Protocol version set to 2024-11-05 for maximum client compatibility"

patterns-established:
  - "AshAi extension: Add `extensions: [AshAi]` to domain, define `tools` block for MCP exposure"
  - "Embedded health resource: Generic action with `run fn` for computed data, no DB dependency"
  - "MCP dev server: AshAi.Mcp.Dev plug inside code_reloading? block for dev-only access"

requirements-completed: [AI-01, AI-02]

# Metrics
duration: 12min
completed: 2026-03-10
---

# Phase 2 Plan 01: MCP Dev Server Summary

**Ash AI MCP dev server with System/Health domain, introspection tools, and mcp-remote transport for Claude Code**

## Performance

- **Duration:** ~12 min (across multiple sessions with checkpoint)
- **Started:** 2026-03-10T00:18:00Z
- **Completed:** 2026-03-10T03:04:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 9

## Accomplishments
- System domain with Health resource returning status, version, uptime, and node via generic action
- AshAi.Mcp.Dev plug wired into Phoenix endpoint (dev-only) serving introspection tools
- Claude Code successfully connects to MCP server and discovers Ash domain tools
- .mcp.json committed with mcp-remote transport for immediate developer use

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ash_ai dep and create System/Health domain** - `757c935` (test: RED), `dd8c210` (feat: GREEN)
2. **Task 2: Wire MCP dev server and create .mcp.json** - `b4bc5ed` (feat), `02d76fc` (fix: port conflict and transport type)
3. **Task 3: Verify MCP server connects from Claude Code** - `10dc376` (fix: mcp-remote transport)

## Files Created/Modified
- `lib/astraplex/system/system.ex` - System Ash domain with AshAi extension and tools block
- `lib/astraplex/system/health.ex` - Health embedded resource with :check generic action
- `test/astraplex/system/health_test.exs` - Integration test for Health :check action
- `.mcp.json` - Claude Code MCP server config using mcp-remote command transport
- `lib/astraplex_web/endpoint.ex` - Added AshAi.Mcp.Dev plug in code_reloading block
- `mix.exs` - Added ash_ai ~> 0.5 dependency
- `mix.lock` - Updated lock file
- `config/config.exs` - Registered Astraplex.System in ash_domains
- `config/runtime.exs` - MCP server runtime config

## Decisions Made
- Used mcp-remote npx command transport instead of direct HTTP/SSE type -- Claude Code requires command/args format
- AshAi.Mcp.Dev only exposes introspection tools, not domain action tools -- separate production MCP router needed (Plan 02-02)
- Health resource uses embedded data layer with no DB dependency -- suitable for operational health checks
- Protocol version 2024-11-05 chosen for maximum client compatibility (ash_ai implements 2025-03-26 internally)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test port conflict**
- **Found during:** Task 2 (Wire MCP dev server)
- **Issue:** Test suite had port conflict with MCP server configuration
- **Fix:** Corrected MCP transport type configuration and resolved port conflict
- **Files modified:** config/runtime.exs, .mcp.json
- **Committed in:** `02d76fc`

**2. [Rule 1 - Bug] Fixed MCP transport format for Claude Code**
- **Found during:** Task 3 checkpoint verification
- **Issue:** Claude Code does not support direct HTTP/SSE type in .mcp.json -- requires command/args format
- **Fix:** Switched to mcp-remote npx command pattern which bridges HTTP MCP to stdio transport
- **Files modified:** .mcp.json
- **Committed in:** `10dc376`

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for correct MCP connectivity. No scope creep.

## Issues Encountered
- AshAi.Mcp.Dev serves introspection tools only (list_ash_resources, get_usage_rules, list_generators), not domain action tools like check_health. This is by design -- domain tools require a production MCP router. Plan 02-02 has been created to address this.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- MCP dev server operational -- Claude Code can discover Ash domains during development
- Plan 02-02 needed to expose domain action tools (check_health, etc.) via production MCP router
- Future domains with AshAi extension will be auto-discovered by otp_app config

## Self-Check: PASSED

All 5 key files verified present. All 5 task commits verified in git history.

---
*Phase: 02-ai-tooling*
*Completed: 2026-03-10*
