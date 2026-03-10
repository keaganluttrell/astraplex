# Phase 2: AI Tooling - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Build an MCP server that exposes Ash domains as tools for AI agents (Claude Code) during development. Scaffold a minimal System/Health domain so the MCP server has something real to expose and validate end-to-end. The MCP server auto-discovers new domains as they are added in later phases.

AI-01 redefined: "MCP server configured in Claude Code so AI agents can interact with Ash domains during development." In-app AI features (Ash AI powering user-facing features) are deferred to v2.

</domain>

<decisions>
## Implementation Decisions

### MCP Server Scope
- Dev-time tooling only — AI agents use MCP to interact with Ash domains during development
- Not a production assistant — no user-facing AI features in v1
- All Ash domain actions exposed as MCP tools automatically (no curation)
- Full introspection included — agents can discover resources, attributes, relationships, and policies
- Auto-discovers new domains as they're added in later phases (no manual registration)

### MCP Transport
- stdio transport — Claude Code launches the server as a subprocess
- No HTTP/SSE needed for single-developer local dev use case

### Domain Bootstrapping
- Scaffold a permanent System/Health domain with a simple Health resource (status, version, uptime)
- Validates the full MCP pipeline end-to-end (domain -> MCP server -> Claude Code)
- Stays permanently — useful for ops/monitoring and as a reference domain
- When Phase 3 adds Accounts domain, it's automatically available via MCP with no config changes

### AI Agent Access
- Claude Code is the only consumer
- No authentication — local dev only, stdio transport
- Full admin policy bypass — MCP actions are unrestricted for dev tooling
- MCP server runs in dev environment only (test uses Smokestack factories)

### MCP Configuration
- Commit `.mcp.json` to the repo — any developer who clones gets MCP ready to use
- MCP server ready to use in Claude Code immediately after Phase 2 completes

### Requirement Redefinition
- AI-01 redefined from "Ash AI integration (use case TBD)" to "MCP server configured in Claude Code for development interaction with Ash domains"
- AI-02 unchanged: "MCP server exposing Ash domains as tools for AI agents"
- Both requirements are now satisfied by the same deliverable: the MCP server

### Claude's Discretion
- Exact System/Health domain structure (attributes, actions beyond basic health check)
- MCP server implementation details (how Ash AI exposes actions)
- `.mcp.json` configuration format and content

</decisions>

<specifics>
## Specific Ideas

- "I want you to use the MCP tools to aid in your development right away" — the MCP server should be immediately useful starting Phase 3
- Both data seeding (create test users, channels, messages) and domain exploration (inspect resources, schemas, policies) are equally valuable workflows
- MCP server should be self-describing — agents discover what's available without needing external docs

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No AI-related code exists yet — greenfield for MCP server
- Ash Framework 3.x already in deps (ash, ash_postgres, ash_phoenix)
- No Ash domains or resources exist yet (only application.ex, repo.ex, mailer.ex)

### Established Patterns
- Ash-native tools preferred over external libraries (from Phase 1 context)
- Domain-driven architecture with strict resource boundaries (from CLAUDE.md)
- All data access through Ash actions, never raw Ecto

### Integration Points
- `.mcp.json` at project root for Claude Code config
- System/Health domain lives in `lib/astraplex/system/` following domain directory convention
- MCP server connects to existing Ash/Phoenix application infrastructure
- Future domains (Accounts in Phase 3, Messaging in Phase 4+) auto-discovered by MCP

</code_context>

<deferred>
## Deferred Ideas

- In-app AI features (Ash AI powering user-facing features) — deferred to v2
- AI-powered message search — deferred to v2 (SRCH-01/SRCH-02)
- Smart channel suggestions via AI — deferred to v2
- Production AI assistant using MCP — future consideration

</deferred>

---

*Phase: 02-ai-tooling*
*Context gathered: 2026-03-09*
