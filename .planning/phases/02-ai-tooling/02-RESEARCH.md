# Phase 2: AI Tooling - Research

**Researched:** 2026-03-09
**Domain:** Ash AI MCP server, Ash domain bootstrapping, Claude Code MCP integration
**Confidence:** HIGH

## Summary

Phase 2 delivers an MCP server that exposes Ash domain actions as tools for Claude Code during development. The `ash_ai` library (v0.5.0) provides a pre-built MCP server via `AshAi.Mcp.Dev` that auto-discovers all Ash domains extended with the `AshAi` extension. The dev server runs as an HTTP endpoint (Streamable HTTP transport) inside the Phoenix application -- not stdio as originally discussed. Claude Code supports HTTP transport natively, so the `.mcp.json` configuration points to `http://localhost:4000/ash_ai/mcp`.

A System domain with a Health resource is scaffolded to validate the MCP pipeline end-to-end. This domain uses the `AshAi` extension with a `tools` block to expose its actions. When future domains (Accounts, Messaging) are added with the same extension pattern, `AshAi.Mcp.Dev` auto-discovers them via the `otp_app` parameter -- no manual registration required.

**Primary recommendation:** Use `AshAi.Mcp.Dev` plug in the Phoenix endpoint (dev-only) with HTTP transport in `.mcp.json`. Scaffold a permanent System domain with Health resource to validate the full pipeline.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Dev-time tooling only -- AI agents use MCP to interact with Ash domains during development
- Not a production assistant -- no user-facing AI features in v1
- All Ash domain actions exposed as MCP tools automatically (no curation)
- Full introspection included -- agents can discover resources, attributes, relationships, and policies
- Auto-discovers new domains as they're added in later phases (no manual registration)
- Scaffold a permanent System/Health domain with a simple Health resource (status, version, uptime)
- Claude Code is the only consumer
- No authentication -- local dev only
- Full admin policy bypass -- MCP actions are unrestricted for dev tooling
- MCP server runs in dev environment only
- Commit `.mcp.json` to the repo
- AI-01 redefined to "MCP server configured in Claude Code for development interaction with Ash domains"
- AI-02 unchanged: "MCP server exposing Ash domains as tools for AI agents"
- Both requirements satisfied by the same deliverable: the MCP server

### Claude's Discretion
- Exact System/Health domain structure (attributes, actions beyond basic health check)
- MCP server implementation details (how Ash AI exposes actions)
- `.mcp.json` configuration format and content

### Deferred Ideas (OUT OF SCOPE)
- In-app AI features (Ash AI powering user-facing features) -- deferred to v2
- AI-powered message search -- deferred to v2 (SRCH-01/SRCH-02)
- Smart channel suggestions via AI -- deferred to v2
- Production AI assistant using MCP -- future consideration
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AI-01 | Ash AI integration (redefined: MCP server configured in Claude Code for dev interaction) | AshAi.Mcp.Dev plug + .mcp.json with HTTP transport enables Claude Code to connect to the MCP server |
| AI-02 | MCP server exposing Ash domains as tools for AI agents | AshAi extension on domains with `tools` block auto-exposes actions; AshAi.Mcp.Dev auto-discovers all extended domains via otp_app |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ash_ai | ~> 0.5 | MCP server + domain tool exposure | Official Ash ecosystem library; auto-discovers domains, generates MCP protocol responses |
| ash | ~> 3.0 | Domain framework (already installed) | Foundation for all domain resources and actions |
| ash_postgres | ~> 2.0 | Database layer (already installed) | Required for Health resource persistence |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| igniter | (transitive) | Code generation for ash_ai setup | Used during `mix igniter.install ash_ai` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AshAi.Mcp.Dev (HTTP) | Custom stdio MCP server | HTTP is what ash_ai provides; stdio would require building a custom server from scratch. HTTP works natively with Claude Code. |
| AshAi.Mcp.Dev | AshAi.Mcp.Router (production) | Dev plug is simpler, no auth needed, auto-discovers all tools. Router is for production with auth. |

**Installation:**
```bash
mix igniter.install ash_ai
```

Or manually add to `mix.exs`:
```elixir
{:ash_ai, "~> 0.5"}
```

## Architecture Patterns

### Recommended Project Structure
```
lib/astraplex/
  system/                    # System domain directory
    system.ex                # Ash.Domain with AshAi extension
    health.ex                # Ash.Resource for health checks
lib/astraplex_web/
  endpoint.ex                # AshAi.Mcp.Dev plug added here
config/
  config.exs                 # ash_domains updated with Astraplex.System
.mcp.json                   # Claude Code MCP server config (committed)
```

### Pattern 1: Domain with AshAi Extension
**What:** Extend an Ash domain with AshAi to expose its actions as MCP tools
**When to use:** Every domain that should be accessible via MCP (all of them for dev tooling)
**Example:**
```elixir
# lib/astraplex/system/system.ex
defmodule Astraplex.System do
  @moduledoc "System domain for health checks and operational diagnostics."

  use Ash.Domain, extensions: [AshAi]

  resources do
    resource Astraplex.System.Health
  end

  tools do
    tool :check_health, Astraplex.System.Health, :read
    tool :create_health_check, Astraplex.System.Health, :create
  end
end
```
Source: [ash_ai README](https://github.com/ash-project/ash_ai), [hexdocs](https://hexdocs.pm/ash_ai/readme.html)

### Pattern 2: Health Resource with Policy Bypass
**What:** A simple Ash resource with a policy bypass for dev/MCP access
**When to use:** Resources accessed by MCP in dev without authentication
**Example:**
```elixir
# lib/astraplex/system/health.ex
defmodule Astraplex.System.Health do
  @moduledoc "Health check resource for system diagnostics."

  use Ash.Resource,
    domain: Astraplex.System,
    data_layer: :embedded  # No database table needed

  attributes do
    attribute :status, :atom do
      constraints one_of: [:healthy, :degraded, :unhealthy]
      allow_nil? false
      public? true
    end

    attribute :version, :string do
      public? true
    end

    attribute :uptime_seconds, :integer do
      public? true
    end

    attribute :node, :string do
      public? true
    end
  end

  actions do
    read :read do
      primary? true
      prepare fn query, _context ->
        # Return computed health data
        query
      end
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
```

### Pattern 3: Dev MCP Plug in Endpoint
**What:** Add AshAi.Mcp.Dev to Phoenix endpoint's code_reloading block
**When to use:** Development environment only -- auto-discovers all AshAi-extended domains
**Example:**
```elixir
# In lib/astraplex_web/endpoint.ex, inside code_reloading? block
if code_reloading? do
  plug AshAi.Mcp.Dev,
    protocol_version_statement: "2024-11-05",
    otp_app: :astraplex
  # ... existing plugs
end
```
Source: [AshAi.Mcp.Dev docs](https://hexdocs.pm/ash_ai/AshAi.Mcp.Dev.html)

### Pattern 4: .mcp.json for Claude Code HTTP Transport
**What:** Project-scoped MCP server configuration file for Claude Code
**When to use:** Committed to repo so any developer gets MCP ready to use
**Example:**
```json
{
  "mcpServers": {
    "astraplex": {
      "type": "http",
      "url": "http://localhost:4000/ash_ai/mcp"
    }
  }
}
```
Source: [Claude Code MCP docs](https://code.claude.com/docs/en/mcp)

### Pattern 5: Auto-Discovery via otp_app
**What:** AshAi.Mcp.Dev uses the `otp_app` parameter to scan all loaded modules for Ash domains with the AshAi extension
**When to use:** Always -- this is what enables zero-config domain addition in later phases
**How it works:** When a new domain is created with `use Ash.Domain, extensions: [AshAi]` and registered in `config :astraplex, ash_domains: [...]`, AshAi.Mcp.Dev automatically discovers and exposes its tools

### Anti-Patterns to Avoid
- **Raw Ecto in Health resource:** Even for system diagnostics, use Ash actions. The Health resource should use `:embedded` data layer or computed results via Ash actions.
- **Manual tool registration in MCP config:** Do not list tools explicitly in .mcp.json -- let AshAi.Mcp.Dev auto-discover via otp_app.
- **Production MCP endpoint:** Never mount AshAi.Mcp.Dev outside the `code_reloading?` block.
- **Stdio transport for ash_ai:** ash_ai provides HTTP-based MCP, not stdio. Do not try to wrap it in a stdio adapter.

## Transport Clarification

**Important deviation from CONTEXT.md:** The CONTEXT.md specified stdio transport. However, ash_ai v0.5.0 implements MCP via **Streamable HTTP Transport** (not stdio). Claude Code supports HTTP transport natively via `claude mcp add --transport http`. The `.mcp.json` file uses `"type": "http"` format.

This is actually simpler than stdio -- no subprocess management, the MCP server is part of the running Phoenix dev server. The Phoenix server must be running for Claude Code to connect (standard `mix phx.server` or `iex -S mix phx.server`).

## Protocol Version Note

ash_ai v0.5.0 implements MCP protocol version 2025-03-26. However, many clients have not updated to this version. Use `protocol_version_statement: "2024-11-05"` for maximum compatibility with Claude Code and other tools.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MCP server | Custom MCP protocol implementation | AshAi.Mcp.Dev | Handles JSON-RPC, session management, SSE, tool discovery automatically |
| Tool exposure | Custom API for each domain action | AshAi `tools` DSL block | Declarative, auto-generates tool schemas from Ash action definitions |
| Domain discovery | Manual registration of new domains | AshAi `otp_app` parameter | Scans application modules at startup, zero config for new domains |
| Health check endpoint | Custom Plug or controller | Ash resource with `:embedded` data layer | Consistent with domain-driven architecture, testable via Ash actions |

**Key insight:** ash_ai handles ALL MCP protocol complexity. The implementation work is: (1) add the dep, (2) add the plug, (3) define tools on domains. Everything else is automatic.

## Common Pitfalls

### Pitfall 1: Protocol Version Mismatch
**What goes wrong:** Claude Code fails to connect or shows protocol errors
**Why it happens:** ash_ai v0.5.0 implements protocol 2025-03-26 but many clients expect 2024-11-05
**How to avoid:** Set `protocol_version_statement: "2024-11-05"` in the Dev plug configuration
**Warning signs:** Connection errors, "unsupported protocol version" messages

### Pitfall 2: Phoenix Server Not Running
**What goes wrong:** Claude Code reports "connection refused" for MCP tools
**Why it happens:** HTTP transport requires the Phoenix server to be running
**How to avoid:** Always start with `mix phx.server` or `iex -S mix phx.server` before using MCP tools in Claude Code
**Warning signs:** MCP tool calls fail with network errors

### Pitfall 3: Domain Not Registered in Config
**What goes wrong:** MCP server starts but no tools appear
**Why it happens:** New domain not added to `config :astraplex, ash_domains: [...]`
**How to avoid:** Always register new domains in config.exs when creating them
**Warning signs:** `/mcp` in Claude Code shows zero tools

### Pitfall 4: Private Attributes Not Visible
**What goes wrong:** MCP tool responses missing expected fields
**Why it happens:** Only `public?: true` attributes are exposed in tool schemas
**How to avoid:** Mark attributes as `public? true` on resources that should be fully visible via MCP
**Warning signs:** Tool responses have fewer fields than expected

### Pitfall 5: Missing AshAi Extension on Domain
**What goes wrong:** Domain exists but its actions don't appear as MCP tools
**Why it happens:** Domain uses `use Ash.Domain` without `extensions: [AshAi]`
**How to avoid:** Every domain that should be MCP-accessible needs `extensions: [AshAi]` and a `tools` block
**Warning signs:** Domain works via Ash actions but invisible to MCP

### Pitfall 6: Embedded Resource for Health
**What goes wrong:** Trying to use database-backed resource for health checks that don't need persistence
**Why it happens:** Defaulting to AshPostgres data layer out of habit
**How to avoid:** Use `data_layer: :embedded` for computed/in-memory resources like health status. Alternatively, if you want to store health check history, use AshPostgres with a migration.
**Warning signs:** Unnecessary migrations, empty tables

## Code Examples

### Complete System Domain Setup
```elixir
# lib/astraplex/system/system.ex
defmodule Astraplex.System do
  @moduledoc "System domain for health checks and operational diagnostics."

  use Ash.Domain, extensions: [AshAi]

  resources do
    resource Astraplex.System.Health
  end

  tools do
    tool :check_health, Astraplex.System.Health, :check
  end
end
```
Source: [ash_ai tool DSL](https://hexdocs.pm/ash_ai/readme.html)

### Health Resource with Computed Data
```elixir
# lib/astraplex/system/health.ex
defmodule Astraplex.System.Health do
  @moduledoc "Health check resource providing system status information."

  use Ash.Resource,
    domain: Astraplex.System,
    data_layer: :embedded

  attributes do
    attribute :status, :atom do
      constraints one_of: [:healthy, :degraded, :unhealthy]
      allow_nil? false
      public? true
    end

    attribute :version, :string do
      allow_nil? false
      public? true
    end

    attribute :uptime_seconds, :integer do
      allow_nil? false
      public? true
    end

    attribute :node, :string do
      public? true
    end
  end

  actions do
    action :check, :struct do
      constraints instance_of: __MODULE__
      description "Returns current system health status"

      run fn _input, _context ->
        {uptime_seconds, _} = :erlang.statistics(:wall_clock)

        {:ok, %__MODULE__{
          status: :healthy,
          version: Application.spec(:astraplex, :vsn) |> to_string(),
          uptime_seconds: div(uptime_seconds, 1000),
          node: Node.self() |> to_string()
        }}
      end
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
```

### Endpoint Configuration
```elixir
# lib/astraplex_web/endpoint.ex (inside code_reloading? block)
if code_reloading? do
  plug AshAi.Mcp.Dev,
    protocol_version_statement: "2024-11-05",
    otp_app: :astraplex,
    path: "/ash_ai/mcp"

  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader
  plug Phoenix.Ecto.CheckRepoStatus, otp_app: :astraplex
end
```

### Config Registration
```elixir
# config/config.exs
config :astraplex, ash_domains: [Astraplex.System]
```

### .mcp.json
```json
{
  "mcpServers": {
    "astraplex": {
      "type": "http",
      "url": "http://localhost:4000/ash_ai/mcp"
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom MCP servers in Elixir | AshAi.Mcp.Dev built-in | ash_ai 0.3.0 (Oct 2025) | No custom MCP code needed |
| SSE transport for MCP | Streamable HTTP transport | MCP spec 2025-03-26 | SSE deprecated, HTTP preferred |
| Manual tool registration | Auto-discovery via otp_app | ash_ai 0.3.0+ | Zero-config for new domains |
| protocol_version "2024-11-05" | protocol_version "2025-03-26" | Jan 2026 | Use older version for compatibility |

**Deprecated/outdated:**
- SSE transport: Deprecated in favor of Streamable HTTP. Claude Code still supports it but HTTP is recommended.
- `AshAi.Mcp.Router` for dev: Use `AshAi.Mcp.Dev` in development. Router is for production with auth.

## Open Questions

1. **Embedded vs Database-backed Health Resource**
   - What we know: `:embedded` data layer works for computed/in-memory data. AshPostgres works for persisted data.
   - What's unclear: Whether an embedded resource with a generic action properly exposes through MCP tools, or if a read action on a database-backed resource is more reliable.
   - Recommendation: Start with `:embedded` + generic action. If MCP discovery has issues, fall back to a simple database-backed resource with a read action.

2. **AshAi.Mcp.Dev Plug Ordering**
   - What we know: The plug goes in the `code_reloading?` block of the endpoint.
   - What's unclear: Whether it must come before or after other plugs in that block.
   - Recommendation: Place it first in the `code_reloading?` block, before LiveReloader and CodeReloader.

3. **Tool Schema for Generic Actions**
   - What we know: `tool :name, Resource, :action` syntax is documented for standard CRUD actions (read, create, update, destroy).
   - What's unclear: Whether generic actions (non-CRUD) like `:check` expose correctly as MCP tools with the right input/output schemas.
   - Recommendation: Test with a simple generic action first. If it doesn't work, use a standard `:read` action with a manual action body.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | test/test_helper.exs |
| Quick run command | `mix test test/astraplex/system/` |
| Full suite command | `mix test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-01 | MCP server responds to Claude Code connections | integration | `mix test test/astraplex/system/health_test.exs -x` | No -- Wave 0 |
| AI-02 | Ash domain actions exposed as MCP tools | integration | `mix test test/astraplex/system/health_test.exs -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/astraplex/system/`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/astraplex/system/health_test.exs` -- integration test for Health resource actions
- [ ] Verify System domain compiles and tools are discoverable (compile-time check)
- [ ] Verify MCP endpoint responds (manual check: start server, connect Claude Code)

Note: MCP protocol integration testing (verifying Claude Code can actually connect and call tools) is inherently manual -- it requires the Phoenix server running and Claude Code connecting. The automated tests validate that the Ash domain, resources, and actions work correctly. The MCP layer is provided by ash_ai and does not need custom testing.

## Sources

### Primary (HIGH confidence)
- [ash_ai hexdocs v0.5.0](https://hexdocs.pm/ash_ai/readme.html) -- MCP server setup, tool DSL, Dev plug configuration
- [ash_ai hex.pm](https://hex.pm/packages/ash_ai) -- Version 0.5.0, released Jan 26 2026
- [Claude Code MCP docs](https://code.claude.com/docs/en/mcp) -- .mcp.json format, HTTP transport, scope configuration
- [ash_ai GitHub](https://github.com/ash-project/ash_ai) -- Source code, README, installation

### Secondary (MEDIUM confidence)
- [DeepWiki ash_ai analysis](https://deepwiki.com/ash-project/ash_ai/6.1-mcp-server-setup) -- Architecture details, auto-discovery mechanism
- [Alembic blog post](https://alembic.com.au/blog/ash-ai-comprehensive-llm-toolbox-for-ash-framework) -- Feature overview, use cases

### Tertiary (LOW confidence)
- Protocol version compatibility between 2025-03-26 and 2024-11-05 -- verified by multiple sources but untested in this specific stack

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- ash_ai is the official Ash ecosystem library, well-documented
- Architecture: HIGH -- patterns follow official docs and ash_ai README exactly
- Pitfalls: MEDIUM -- protocol version and auto-discovery details from multiple sources but not personally validated
- Transport clarification: HIGH -- ash_ai clearly uses HTTP, Claude Code clearly supports HTTP

**Research date:** 2026-03-09
**Valid until:** 2026-04-09 (ash_ai is actively developed, check for updates)
