# Phase 1: Engineering Quality - Research

**Researched:** 2026-03-09
**Domain:** Elixir/Phoenix/Ash project scaffolding, test infrastructure, static analysis, git hooks, design system
**Confidence:** HIGH

## Summary

Phase 1 establishes the engineering foundation for a greenfield Elixir/Phoenix/Ash/LiveView project. The core deliverables are: (1) an integration test suite with Ash-native factories via Smokestack, (2) E2E browser tests via PhoenixTest + Playwright, (3) static analysis via Credo (strict) + Dialyxir, (4) git hooks via the `git_hooks` Elixir package, (5) CLAUDE.md with strict conventions, and (6) a design system using DaisyUIComponents on top of Phoenix 1.8's built-in daisyUI support.

Phoenix 1.8 ships with Tailwind CSS 4 and daisyUI 5 out of the box, which simplifies the design system bootstrap significantly. The project scaffold (`mix phx.new`) provides the starting point, and this phase layers quality infrastructure on top. All tools selected are Elixir-native where possible, matching the user's preference for Ash-native tooling.

**Primary recommendation:** Use the Elixir ecosystem's standard quality tools (Credo strict + Dialyxir, git_hooks, Smokestack, PhoenixTestPlaywright, DaisyUIComponents) -- all are well-maintained, work with Phoenix 1.8 / Ash 3.x, and avoid hand-rolling infrastructure.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use daisyUI (ships with Phoenix 1.8+) with DaisyUIComponents library for LiveView-native components
- Light/corporate theme direction -- clean white backgrounds, subtle grays, professional feel (like Linear/Notion/Slack light mode)
- Stock daisyUI theme (no custom brand colors) -- can customize later
- Core primitives only in Phase 1: Button, Input, Badge, Avatar, Card, Modal -- enough to build auth screens in Phase 3
- Expand component library as needed in later phases
- Conventional Commits with domain-scoped types: `feat(messaging):`, `fix(auth):`, `test(accounts):`, etc.
- Scopes match Ash domains (accounts, messaging, notifications) plus infra, deps, docs, test
- Strict guardrails in CLAUDE.md -- hard rules, not guidelines (NEVER raw Ecto, domains MUST NOT cross, policies on EVERY action, integration test for every action, no business logic in LiveView)
- Explicit file conventions (module structure order, ~300 line cap, @doc on public functions, typespecs on public API)
- Thin LiveViews (<150 lines target)
- Pre-commit blocks on: format check, compilation (warnings-as-errors), static analysis
- Pre-push blocks on: full test suite -- E2E tests are CI-only, not in hooks
- Warnings-as-errors: yes, zero tolerance
- No bypass allowed -- hooks always enforced, no `--no-verify`
- Test factories: Ash actions + Smokestack (Ash-native factory library)
- No ExMachina -- it bypasses Ash and inserts directly via Ecto

### Claude's Discretion
- E2E tool selection (after research evaluates options)
- Static analysis tool configuration and strictness level (after research)
- Specific daisyUI theme choice between 'corporate' and 'light'
- Loading skeleton and error state patterns for design system
- Exact Smokestack configuration and helper module structure
- Git hook implementation approach (lefthook, husky, custom scripts)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| QUAL-01 | Integration test suite covering Ash actions, policies, and PubSub behavior | Ash testing patterns, Smokestack factories, DataCase/ConnCase setup |
| QUAL-02 | E2E test suite covering full user flows through LiveView (tool TBD by research) | PhoenixTestPlaywright v0.13.0 recommended -- integrates with PhoenixTest API, Ecto sandbox, Playwright browsers |
| QUAL-03 | Static analysis and compile-time type checking (tools TBD by research) | Credo v1.7.x (strict mode) + Dialyxir v1.4.x recommended |
| QUAL-04 | Git pre-commit hook (format check, compile, static analysis) | git_hooks v0.8.0 with mix tasks for format, compile, credo, dialyzer |
| QUAL-05 | Git pre-push hook (run test suite) | git_hooks v0.8.0 with `mix test` task |
| QUAL-06 | Test harness with standardized setup, factories, and helper modules | Smokestack v0.9.2 for factories, custom test helpers, Ash test config |
| QUAL-07 | AI usage rules (CLAUDE.md) encoding code conventions, architecture rules, commit conventions | User-provided conventions in CONTEXT.md, documented patterns |
| QUAL-08 | Design system with consistent component library | DaisyUIComponents v0.9.3 on Phoenix 1.8 daisyUI 5 with corporate/light theme |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.x | Web framework | Ships with Tailwind 4 + daisyUI 5 out of the box |
| Ash Framework | 3.19.x | Domain-driven application framework | Project's core architecture |
| AshPostgres | latest | Postgres data layer for Ash | Required for Ash + Postgres |
| DaisyUIComponents | ~> 0.9 | LiveView component library wrapping daisyUI | 60+ pre-built LiveView components, replaces CoreComponents |
| Smokestack | ~> 0.9 | Ash-native test factory library | DSL for Ash resource factories, Ash ecosystem project |
| PhoenixTestPlaywright | ~> 0.12 | E2E browser testing | PhoenixTest API + Playwright browsers, Ecto sandbox support, async tests |
| Credo | ~> 1.7 | Static code analysis | Standard Elixir linter, strict mode available |
| Dialyxir | ~> 1.4 | Dialyzer mix tasks | Type checking via Dialyzer, PLT management |
| git_hooks | ~> 0.8.0 | Git hook management | Elixir-native, auto-installs hooks after `mix deps.compile` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Faker | ~> 0.18 | Test data generation | Generating realistic test data in Smokestack factories |
| Floki | (dep of Phoenix) | HTML parsing | Already included, useful for test assertions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PhoenixTestPlaywright | Wallaby | Wallaby is more mature but uses older Selenium/ChromeDriver model; PhoenixTestPlaywright uses modern Playwright, integrates with PhoenixTest API, supports concurrent async tests via Ecto sandbox, and is the direction the Phoenix ecosystem is heading |
| PhoenixTestPlaywright | playwright-elixir | Lower level, WIP, far from feature complete, only Chromium supported |
| git_hooks | Lefthook | Lefthook is language-agnostic (Go binary) with parallel execution; git_hooks is Elixir-native, configured in mix config, auto-installs on deps.compile -- better DX for Elixir projects |
| git_hooks | Custom shell scripts | No auto-install, manual management, easy to forget setup |
| Smokestack | ExMachina | ExMachina bypasses Ash and inserts directly via Ecto -- violates the "all data through Ash" principle |

**Installation:**
```elixir
# mix.exs deps
{:daisy_ui_components, "~> 0.9"},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
{:smokestack, "~> 0.9", only: :test},
{:faker, "~> 0.18", only: :test},
{:phoenix_test_playwright, "~> 0.12", only: :test, runtime: false},
{:git_hooks, "~> 0.8.0", only: :dev, runtime: false}
```

```bash
# After mix deps.get, install Playwright browsers
npm --prefix assets i -D playwright
npx --prefix assets playwright install chromium --with-deps
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
  astraplex/              # Business logic (Ash domains)
    accounts/             # Accounts domain (future phases)
    messaging/            # Messaging domain (future phases)
  astraplex_web/          # Web layer
    components/           # Design system components
      core_components.ex  # Project-specific component overrides
    layouts/              # Layout templates
test/
  astraplex/              # Integration tests for Ash actions
  astraplex_web/          # LiveView / controller tests
  e2e/                    # E2E browser tests (PhoenixTestPlaywright)
  support/                # Test helpers
    factory.ex            # Smokestack factory definitions
    conn_case.ex          # ConnCase with auth helpers
    data_case.ex          # DataCase for domain tests
    e2e_case.ex           # E2E test case module
```

### Pattern 1: Smokestack Factory Module
**What:** Centralized factory definitions for Ash resources using Smokestack DSL
**When to use:** Every test that needs test data
**Example:**
```elixir
# test/support/factory.ex
defmodule Astraplex.Factory do
  use Smokestack

  # Factories will be added as resources are created in later phases
  # Example pattern (for Phase 3):
  # factory Astraplex.Accounts.User do
  #   attribute :email, &Faker.Internet.email/0
  #   attribute :name, &Faker.Person.name/0
  # end
end
```

### Pattern 2: Ash Test Configuration
**What:** Required Ash configuration for test environment
**When to use:** config/test.exs setup
**Example:**
```elixir
# config/test.exs
config :ash, :disable_async?, true
config :ash, :missed_notifications, :ignore
```

### Pattern 3: E2E Test Case Module
**What:** Base module for Playwright-driven browser tests
**When to use:** All E2E tests
**Example:**
```elixir
# test/support/e2e_case.ex
defmodule AstraplexWeb.E2ECase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use PhoenixTest.Playwright.Case
    end
  end
end
```

### Pattern 4: PhoenixTestPlaywright Test
**What:** E2E browser test using PhoenixTest API
**When to use:** Testing full user flows through LiveView
**Example:**
```elixir
# test/e2e/smoke_test.exs
defmodule AstraplexWeb.E2E.SmokeTest do
  use AstraplexWeb.E2ECase, async: true

  test "homepage loads", %{conn: conn} do
    conn
    |> visit(~p"/")
    |> assert_has("body .phx-connected")
  end
end
```

### Pattern 5: DaisyUIComponents Integration
**What:** Import DaisyUIComponents to replace default CoreComponents
**When to use:** web.ex setup
**Example:**
```elixir
# lib/astraplex_web.ex (in html_helpers or similar)
defp html_helpers do
  quote do
    use DaisyUIComponents
    # ... other imports
  end
end
```

### Anti-Patterns to Avoid
- **Raw Ecto in tests:** Never use `Repo.insert!` directly -- use Smokestack factories or Ash actions for test setup
- **ExMachina factories:** Bypasses Ash lifecycle (validations, policies, calculations) -- use Smokestack instead
- **Business logic in LiveViews:** LiveViews should delegate to Ash actions, not contain domain logic
- **Skipping hooks:** No `--no-verify` -- if hooks are slow, optimize them, don't bypass them
- **Testing implementation details:** Test Ash action behavior and policies, not internal function calls

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test factories | Custom factory functions | Smokestack | DSL-driven, Ash-native, handles relationships, supports variants |
| E2E browser testing | Selenium scripts, raw HTTPoison tests | PhoenixTestPlaywright | Ecto sandbox integration, async concurrent tests, PhoenixTest API compatibility |
| Static analysis | Custom mix tasks checking code | Credo + Dialyxir | Comprehensive rule sets, community maintained, IDE integration |
| Git hooks | Shell scripts in .git/hooks | git_hooks package | Auto-installs on deps.compile, configured in Elixir, no manual setup |
| Component library | Custom Tailwind components from scratch | DaisyUIComponents | 60+ pre-built components, Phoenix generator compatible, maintained |
| Code formatting | Custom formatter rules | `mix format` (built-in) | Ships with Elixir, zero config needed |

**Key insight:** This phase is entirely about infrastructure -- every piece has a well-maintained Elixir package. Hand-rolling any of these means maintaining infrastructure instead of building features.

## Common Pitfalls

### Pitfall 1: Smokestack Uses Ash.Seed (Bypasses Actions)
**What goes wrong:** Smokestack's `insert!/2` uses `Ash.Seed.seed!/2`, which bypasses Ash actions, validations, and policies. Tests that rely on factory-inserted data may not catch validation bugs.
**Why it happens:** Smokestack is designed for convenience -- fast test data setup without going through the full Ash lifecycle.
**How to avoid:** Use Smokestack for setting up prerequisite data (users, channels that need to exist). For the actual behavior being tested, always invoke Ash actions directly. The user's CONTEXT.md already prescribes this: "test setup goes through real Ash actions where fidelity matters, Smokestack for convenience with bulk data."
**Warning signs:** Tests pass but production code fails on validations that factories never triggered.

### Pitfall 2: Dialyzer PLT Build Time on First Run
**What goes wrong:** First `mix dialyzer` run builds the PLT (Persistent Lookup Table) and can take 5-15 minutes. This blocks the pre-commit hook.
**Why it happens:** Dialyzer needs to analyze all dependencies to build its type database.
**How to avoid:** Run `mix dialyzer` once after project setup to build the PLT before enabling hooks. Consider running Dialyzer only on pre-push (not pre-commit) to avoid blocking frequent commits. The PLT is cached in `_build` and rebuilds are incremental.
**Warning signs:** Developers complaining that commits take minutes.

### Pitfall 3: PhoenixTestPlaywright Requires Server Mode
**What goes wrong:** E2E tests fail because the Phoenix endpoint is not running.
**Why it happens:** Playwright needs a real HTTP server to connect to, unlike LiveViewTest which runs in-process.
**How to avoid:** Set `config :your_app, YourAppWeb.Endpoint, server: true` in `config/test.exs`. Also start the Playwright supervisor in `test/test_helper.exs`.
**Warning signs:** Connection refused errors in E2E tests.

### Pitfall 4: Ecto Sandbox with E2E Tests
**What goes wrong:** E2E tests see stale data or interfere with each other.
**Why it happens:** Browser requests run in separate processes from the test process, requiring sandbox allowances.
**How to avoid:** PhoenixTestPlaywright handles this automatically via user agent-based sandbox identification. Ensure `Phoenix.Ecto.SQL.Sandbox` plug is configured in the endpoint for the test environment. Use `async: true` in test modules.
**Warning signs:** Intermittent test failures, data not found errors.

### Pitfall 5: git_hooks Auto-Install Overwrites Existing Hooks
**What goes wrong:** Existing git hooks get overwritten when `git_hooks` auto-installs.
**Why it happens:** `git_hooks` installs on `mix deps.compile` by default.
**How to avoid:** Since this is a greenfield project, this is not an issue. The library creates `.pre_git_hooks_backup` files as a safety measure. Set `auto_install: true` in config.
**Warning signs:** Lost custom hooks (not relevant for this project).

### Pitfall 6: DaisyUIComponents vs CoreComponents Conflict
**What goes wrong:** Duplicate component definitions cause compilation errors or unexpected rendering.
**Why it happens:** Phoenix generates default CoreComponents; DaisyUIComponents can replace them.
**How to avoid:** Use `use DaisyUIComponents, core_components: true` to fully replace Phoenix's CoreComponents, or `core_components: false` and selectively import. Decide on one approach and stick with it. The `mix daisy` installer handles this automatically.
**Warning signs:** "function already defined" compilation warnings.

## Code Examples

### Credo Strict Configuration
```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      checks: %{
        enabled: [
          # Consistency
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},

          # Design
          {Credo.Check.Design.AliasUsage, [if_nested_deeper_than: 2]},

          # Readability
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [max_length: 120]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.WithCustomTaggedTuple, []},

          # Refactoring
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity, []},
          {Credo.Check.Refactor.FunctionArity, []},
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.Nesting, []},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.WithClauses, []},

          # Warnings
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},
          {Credo.Check.Warning.UnsafeExec, []}
        ],
        disabled: [
          {Credo.Check.Readability.Specs, []}  # Rely on Dialyzer instead
        ]
      }
    }
  ]
}
```

### git_hooks Configuration
```elixir
# config/dev.exs (or config/config.exs wrapped in Mix.env() == :dev)
if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format --check-formatted"},
          {:cmd, "mix compile --warnings-as-errors"},
          {:cmd, "mix credo --strict"}
        ]
      ],
      pre_push: [
        tasks: [
          {:cmd, "mix test --color"}
        ]
      ]
    ]
end
```

### PhoenixTestPlaywright Setup
```elixir
# config/test.exs
config :phoenix_test, otp_app: :astraplex
config :astraplex, AstraplexWeb.Endpoint, server: true

# test/test_helper.exs
{:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
Application.put_env(:phoenix_test, :base_url, AstraplexWeb.Endpoint.url())
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Astraplex.Repo, :manual)
```

### Ash Test Configuration
```elixir
# config/test.exs
config :ash, :disable_async?, true
config :ash, :missed_notifications, :ignore
```

### DaisyUIComponents Theme Setup
```elixir
# In root.html.heex layout
<html data-theme="corporate">
```
```css
/* assets/css/app.css */
@source "../../deps/daisy_ui_components";
```

## Discretion Recommendations

### E2E Tool: PhoenixTestPlaywright (RECOMMENDED)
**Rationale:** PhoenixTestPlaywright (v0.13.0) is the modern choice for Phoenix E2E testing. It uses the PhoenixTest API (same API as in-process LiveView tests), supports concurrent async tests via Ecto sandbox, runs on Playwright (modern browser automation), and is actively maintained. Wallaby is more mature but uses older ChromeDriver/Selenium architecture. The Phoenix team itself uses Playwright for LiveView E2E testing. PhoenixTestPlaywright became production-ready in December 2024.

### Static Analysis: Credo Strict + Dialyxir (RECOMMENDED)
**Rationale:** Use Credo in strict mode -- it enables low-priority checks that catch refactoring opportunities and code smells that default mode misses. Add Dialyxir for compile-time type checking via Dialyzer. Key consideration: Dialyzer's first PLT build takes 5-15 minutes, so include it in pre-commit but warn developers about the initial run. After the PLT is built, incremental checks are fast (seconds).

**Important:** Consider running Dialyzer on pre-push only (not pre-commit) to keep commits fast. Credo is fast enough for pre-commit. This keeps the developer feedback loop tight while still catching type errors before push.

### daisyUI Theme: `corporate` (RECOMMENDED)
**Rationale:** The `corporate` theme best matches the user's description of "clean white backgrounds, subtle grays, professional feel." It has a business-appropriate color palette with blue accents, white backgrounds, and muted secondary colors. The `light` theme is the bare default and lacks the professional polish. Both are stock daisyUI themes requiring zero customization.

### Loading/Error Patterns
**Rationale:** For Phase 1, establish two basic patterns:
1. **Loading skeleton:** Use daisyUI's `loading` component (spinner) for async operations
2. **Error states:** Use daisyUI's `alert` component with `alert-error` variant for form/action errors

These are sufficient for Phase 1. Expand with skeleton placeholders and toast notifications in later phases.

### Smokestack Helper Structure
**Rationale:** Single factory module at `test/support/factory.ex` with all factory definitions. Import in DataCase and ConnCase. No need for separate factory files per domain until the project grows significantly.

### Git Hook Tool: git_hooks (RECOMMENDED)
**Rationale:** Elixir-native, configured in `config/dev.exs`, auto-installs on `mix deps.compile`, no external binary needed. Lefthook is more powerful (parallel execution, Go binary) but adds a non-Elixir dependency. For this project's needs (format check, compile, credo, test), `git_hooks` is sufficient and keeps the stack pure Elixir.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Wallaby + ChromeDriver | PhoenixTestPlaywright | Dec 2024 | Modern Playwright API, concurrent tests, PhoenixTest compatibility |
| ExMachina factories | Smokestack (Ash-native) | 2024 | Ash resource DSL, respects Ash ecosystem |
| Custom shell git hooks | git_hooks Elixir package | 2022+ | Auto-install, Elixir-native config |
| Manual daisyUI setup | Phoenix 1.8 ships daisyUI | 2025 | Zero setup for base daisyUI; DaisyUIComponents adds LiveView wrappers |
| Tailwind CSS 3 | Tailwind CSS 4 | 2025 | Ships with Phoenix 1.8, new `@source` directive |
| CoreComponents (Phoenix default) | DaisyUIComponents | 2024-2025 | 60+ pre-styled components, generator compatible |

**Deprecated/outdated:**
- `live_daisyui_components`: Deprecated in favor of `daisy_ui_components` (same author, renamed)
- Wallaby Playwright driver: Discussion exists (#753) but PhoenixTestPlaywright is the community solution
- `pre_commit` hex package: Unmaintained, use `git_hooks` instead

## Open Questions

1. **Dialyzer in pre-commit vs pre-push**
   - What we know: Dialyzer is fast after initial PLT build, but can add 5-10 seconds to each commit
   - What's unclear: Whether the team will find this acceptable in pre-commit
   - Recommendation: Start with Dialyzer in pre-push only, promote to pre-commit if the team wants stricter checks. Credo in pre-commit is fast and catches most issues.

2. **DaisyUIComponents core_components option**
   - What we know: Can set `core_components: true` to fully replace Phoenix defaults, or `false` to keep both
   - What's unclear: Which Phoenix generator components the project will need to customize
   - Recommendation: Use the `mix daisy` installer which handles this automatically. Start with `core_components: true` (full replacement) since the project is greenfield.

3. **E2E test organization**
   - What we know: PhoenixTestPlaywright tests can live anywhere in `test/`
   - What's unclear: Best tagging/organization strategy to separate E2E from integration tests for the hook setup (E2E is CI-only per user decision)
   - Recommendation: Use ExUnit tags (`@moduletag :e2e`) and exclude in test_helper.exs by default: `ExUnit.configure(exclude: [:e2e])`. CI runs `mix test --include e2e`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir) + PhoenixTestPlaywright v0.13.0 |
| Config file | `config/test.exs` (to be created with scaffold) |
| Quick run command | `mix test --exclude e2e` |
| Full suite command | `mix test --include e2e` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QUAL-01 | Integration test suite runs with factories | smoke | `mix test test/astraplex/ --exclude e2e` | No -- Wave 0 |
| QUAL-02 | E2E tests execute browser tests | smoke | `mix test test/e2e/ --include e2e` | No -- Wave 0 |
| QUAL-03 | Static analysis passes | manual | `mix credo --strict && mix dialyzer` | No -- Wave 0 |
| QUAL-04 | Pre-commit hook rejects bad code | manual-only | Manual: commit badly formatted code, verify rejection | N/A |
| QUAL-05 | Pre-push hook rejects failing tests | manual-only | Manual: push with failing test, verify rejection | N/A |
| QUAL-06 | Factories and helpers available | smoke | `mix test test/support/factory_test.exs` | No -- Wave 0 |
| QUAL-07 | CLAUDE.md exists with conventions | manual-only | Check file exists and contains required sections | N/A |
| QUAL-08 | Design system components render | smoke | `mix test test/astraplex_web/components/` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test --exclude e2e`
- **Per wave merge:** `mix test --exclude e2e && mix credo --strict`
- **Phase gate:** `mix test --include e2e && mix credo --strict && mix dialyzer && mix format --check-formatted`

### Wave 0 Gaps
- [ ] `test/support/factory.ex` -- Smokestack factory module (empty, ready for resources)
- [ ] `test/support/data_case.ex` -- DataCase with Ash test config and factory import
- [ ] `test/support/conn_case.ex` -- ConnCase with auth helper stubs
- [ ] `test/support/e2e_case.ex` -- E2E case module wrapping PhoenixTestPlaywright
- [ ] `test/e2e/smoke_test.exs` -- Minimal smoke test proving E2E works
- [ ] `.credo.exs` -- Credo strict configuration
- [ ] Framework install: `mix deps.get && npm --prefix assets i -D playwright && npx --prefix assets playwright install chromium --with-deps`

## Sources

### Primary (HIGH confidence)
- [Smokestack v0.9.2 HexDocs](https://hexdocs.pm/smokestack/Smokestack.html) - Factory DSL, insert/build API, Ash.Seed usage
- [DaisyUIComponents v0.9.3 HexDocs](https://hexdocs.pm/daisy_ui_components/DaisyUIComponents.html) - Installation, components, Phoenix 1.8 integration
- [PhoenixTestPlaywright GitHub](https://github.com/ftes/phoenix_test_playwright) - Setup, configuration, Ecto sandbox, async tests
- [PhoenixTestPlaywright v0.13.0 HexDocs](https://hexdocs.pm/phoenix_test_playwright/) - API documentation
- [Credo v1.7.16 Config HexDocs](https://hexdocs.pm/credo/config_file.html) - Strict mode, configuration file format
- [Dialyxir GitHub](https://github.com/jeremyjh/dialyxir) - PLT management, mix dialyzer setup
- [git_hooks GitHub](https://github.com/qgadrian/elixir_git_hooks) - Configuration, auto-install, task types
- [Phoenix 1.8 Release Blog](https://www.phoenixframework.org/blog/phoenix-1-8-released) - daisyUI 5, Tailwind 4 defaults
- [Ash Testing HexDocs](https://hexdocs.pm/ash/testing.html) - Test configuration, disable_async, missed_notifications

### Secondary (MEDIUM confidence)
- [Elixir Forum: LiveViewTest vs Playwright](https://elixirforum.com/t/when-to-use-liveviewtest-vs-playwright/67818) - Community perspective on E2E tool choice
- [Elixir Forum: DaisyUIComponents announcement](https://elixirforum.com/t/daisyuicomponents-a-phoenix-liveview-daisyui-library/69415) - Library status and Phoenix 1.8 compatibility
- [Elixir Forum: Testing Ash best practices](https://elixirforum.com/t/testing-ash-share-your-design-and-best-practices/63238) - Community Ash testing patterns
- [AppSignal: Getting Started with Dialyzer 2025](https://blog.appsignal.com/2025/03/18/getting-started-with-dialyzer-in-elixir.html) - Current Dialyzer best practices

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified on HexDocs with current versions, Phoenix 1.8 daisyUI integration confirmed
- Architecture: HIGH - Patterns follow official Ash and Phoenix documentation
- Pitfalls: HIGH - Documented in official sources (Smokestack/Ash.Seed, Dialyzer PLT, Ecto sandbox)
- E2E tool choice: MEDIUM - PhoenixTestPlaywright is newer (production-ready Dec 2024) but well-documented and actively maintained

**Research date:** 2026-03-09
**Valid until:** 2026-04-09 (30 days - stable ecosystem)
