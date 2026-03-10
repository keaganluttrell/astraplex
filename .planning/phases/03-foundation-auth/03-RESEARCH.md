# Phase 3: Foundation & Auth - Research

**Researched:** 2026-03-09
**Domain:** Authentication, user management, Ash Framework authorization
**Confidence:** HIGH

## Summary

Phase 3 introduces the Accounts domain with user management and authentication using AshAuthentication -- the Ash ecosystem's official authentication extension. AshAuthentication provides password hashing, session management, token storage, and Phoenix LiveView integration out of the box, eliminating the need to hand-roll any auth logic.

The implementation requires: an Accounts domain with User and Token resources, the AshAuthentication extension on the User resource with the password strategy, AshAuthentication.Phoenix for router integration (plugs, sign-in/sign-out routes, LiveSession), a custom sign-in LiveView using DaisyUIComponents for the centered card layout, an admin user management LiveView at /admin/users, a `mix astraplex.create_admin` mix task for bootstrapping, and comprehensive integration tests including negative authorization tests per CVE-2025-48043.

**Primary recommendation:** Use AshAuthentication ~> 4.13 with AshAuthentication.Phoenix ~> 2.15 for the password strategy. Build a custom sign-in LiveView (not the default generated one) to match the centered card aesthetic. Use bcrypt (the AshAuthentication default) for password hashing -- it is secure, well-tested, and avoids an additional dependency.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- First admin created via `mix astraplex.create_admin` mix task (email + password as args, no defaults)
- Admin sets the real password during bootstrap -- no forced password change flow
- Multiple admins allowed -- any admin can create other admin accounts
- Dev seeds (seeds.exs) create sample users: 1 admin + several staff with known credentials
- Centered card layout on neutral background for login -- app name "Astraplex" above the card
- No logo, tagline, or additional branding -- app name text only
- Generic error on failure: "Invalid email or password" -- never reveals account existence
- After successful login, user lands on a dashboard/home page (placeholder for Phase 4+)
- Deactivated users see same generic "Invalid email or password" on login attempt
- Deactivated users appear in admin user lists with "Deactivated" status badge
- Deactivation is reversible -- admin can reactivate accounts
- Active sessions terminated immediately on deactivation
- Deactivated user's display name stays as-is in existing messages
- Modal confirmation before deactivation
- No reason field for deactivation
- Reactivated accounts keep original password
- Single form for user creation: email, password, role (Admin/Staff dropdown)
- Admin sets user's password (communicated out-of-band)
- Roles changeable anytime after creation
- User management lives at /admin/users LiveView page
- Phase 9 will refine into full admin dashboard

### Claude's Discretion
- Auth library choice (AshAuthentication vs custom) -- **Recommendation: AshAuthentication** (see Standard Stack)
- Password hashing algorithm (bcrypt vs argon2) -- **Recommendation: bcrypt** (see Architecture Patterns)
- Session storage strategy (cookie vs database-backed) -- **Recommendation: Cookie-based sessions with database-backed tokens** (see Architecture Patterns)
- Exact dashboard/home page content for post-login landing
- Table design and pagination for admin user list
- MCP endpoint auth -- **Recommendation: Defer further** (Phase 3 scope is already full; MCP auth can be added when needed)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUND-01 | Admin can create user accounts with email and password | AshAuthentication password strategy provides register action; custom admin :create action wraps this with role assignment and actor authorization |
| FOUND-02 | Admin can assign users the Admin or Staff role | Ash enum attribute on User resource with :admin/:staff values; admin :update_role action with policy requiring admin actor |
| FOUND-03 | Admin can deactivate user accounts (soft delete, preserves history) | :status attribute (:active/:deactivated) with :deactivate and :reactivate actions; sign_in action checks status; token revocation on deactivate |
| FOUND-04 | User can log in with email and password | AshAuthentication password strategy :sign_in action; custom sign-in LiveView with DaisyUIComponents |
| FOUND-05 | User session persists across browser refresh | AshAuthentication.Phoenix session plugs + token-backed sessions; cookie stores subject reference, database stores token validity |
| FOUND-06 | User can log out from any page | sign_out_route macro in router pointing to AuthController; clears session and redirects to sign-in |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ash_authentication | ~> 4.13 | Auth extension for Ash resources | Official Ash ecosystem auth; declarative password strategy, token management, session handling |
| ash_authentication_phoenix | ~> 2.15 | Phoenix/LiveView integration | Router macros, session plugs, LiveSession for authenticated LiveViews |
| bcrypt_elixir | (transitive) | Password hashing | Default hash_provider for AshAuthentication; pulled in automatically |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| simple_sat | ~> 0.1 | Policy authorization solver | Already in deps; required for Ash policies on all actions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AshAuthentication | Custom Ash actions + Bcrypt manual | Lose token management, session helpers, LiveSession integration; enormous surface area to maintain |
| bcrypt_elixir | argon2_elixir | Argon2 is theoretically stronger but requires a C NIF, adds compilation complexity; bcrypt is AshAuthentication's default, well-tested, and secure for this use case |
| Cookie sessions | Database sessions (Plug.Session.ETS/PG) | Cookie sessions are Phoenix's default, sufficient for this app; database sessions add complexity without clear benefit for an internal tool |

**Installation:**
```bash
mix deps.get
```

Add to `mix.exs` deps:
```elixir
{:ash_authentication, "~> 4.13"},
{:ash_authentication_phoenix, "~> 2.15"}
```

## Architecture Patterns

### Recommended Project Structure
```
lib/astraplex/
  accounts/               # Accounts domain
    accounts.ex           # Domain module (use Ash.Domain)
    user.ex               # User resource with AshAuthentication
    token.ex              # Token resource (AshAuthentication.TokenResource)
lib/astraplex_web/
  controllers/
    auth_controller.ex    # Handles sign-out, auth callbacks
  live/
    auth_live/
      sign_in_live.ex     # Custom sign-in LiveView
    admin/
      user_list_live.ex   # Admin user management
      user_form_component.ex  # User create/edit form
  plugs/
    require_admin.ex      # Plug/on_mount hook for admin-only routes
lib/mix/tasks/
  astraplex.create_admin.ex  # Bootstrap mix task
```

### Pattern 1: AshAuthentication User Resource
**What:** User resource with password strategy, policies, and custom actions for admin management
**When to use:** This is the single User resource pattern for the entire app

```elixir
defmodule Astraplex.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Accounts

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :role, :atom, constraints: [one_of: [:admin, :staff]], default: :staff, allow_nil?: false, public?: true
    attribute :status, :atom, constraints: [one_of: [:active, :deactivated]], default: :active, allow_nil?: false, public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  authentication do
    tokens do
      enabled? true
      token_resource Astraplex.Accounts.Token
      signing_secret fn _, _ ->
        Application.fetch_env(:astraplex, :token_signing_secret)
      end
    end

    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
        confirmation_required? false
        registration_enabled? false  # No self-signup
      end
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
    # Admin-only actions for user management
    policy action(:create_user) do
      authorize_if expr(^actor(:role) == :admin)
    end
    policy action(:deactivate) do
      authorize_if expr(^actor(:role) == :admin)
    end
    # ... more policies
  end

  postgres do
    table "users"
    repo Astraplex.Repo
  end
end
```

### Pattern 2: Token Resource
**What:** Database-backed token storage for session validation and revocation
**When to use:** Required by AshAuthentication when tokens are enabled

```elixir
defmodule Astraplex.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Accounts

  postgres do
    table "tokens"
    repo Astraplex.Repo
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end
end
```

### Pattern 3: Router with Auth Pipelines
**What:** Separate pipelines for authenticated, unauthenticated, and admin routes
**When to use:** Router configuration

```elixir
defmodule AstraplexWeb.Router do
  use AstraplexWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AstraplexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session  # AshAuthentication plug
  end

  scope "/", AstraplexWeb do
    pipe_through :browser

    # Unauthenticated routes
    sign_in_route(
      path: "/sign-in",
      live_view: AstraplexWeb.AuthLive.SignInLive,
      overrides: [AshAuthentication.Phoenix.Overrides.Default]
    )
    sign_out_route AuthController
    auth_routes AuthController, Astraplex.Accounts.User, path: "/auth"
  end

  # Authenticated routes
  scope "/", AstraplexWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated,
      on_mount: [{AstraplexWeb.LiveAuth, :require_authenticated_user}] do
      live "/", DashboardLive, :index
    end

    ash_authentication_live_session :admin,
      on_mount: [{AstraplexWeb.LiveAuth, :require_admin}] do
      live "/admin/users", Admin.UserListLive, :index
      live "/admin/users/new", Admin.UserListLive, :new
    end
  end
end
```

### Pattern 4: Custom Sign-In LiveView
**What:** Custom LiveView matching the centered card aesthetic instead of default AshAuthentication UI
**When to use:** To match the app's design language

```elixir
defmodule AstraplexWeb.AuthLive.SignInLive do
  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    form = AshPhoenix.Form.for_action(Astraplex.Accounts.User, :sign_in_with_password, as: "user")
    {:ok, assign(socket, form: form, trigger_action: false)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form, trigger_action: form.valid?)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-96 bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="text-2xl font-bold text-center">Astraplex</h1>
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={~p"/auth/user/password/sign_in"}
            method="POST"
          >
            <%!-- email and password fields using DaisyUIComponents --%>
            <%!-- submit button --%>
          </.form>
        </div>
      </div>
    </div>
    ~H"""
  end
end
```

### Pattern 5: LiveAuth on_mount Hook
**What:** on_mount callbacks for protecting LiveView routes
**When to use:** Every authenticated or admin-only LiveView route

```elixir
defmodule AstraplexWeb.LiveAuth do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:require_authenticated_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/sign-in")}
    end
  end

  def on_mount(:require_admin, _params, _session, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.role == :admin do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end
end
```

### Pattern 6: Deactivation with Session Termination
**What:** Deactivate action that also revokes all tokens, forcing logout on next request
**When to use:** FOUND-03 deactivation requirement

The sign_in action must check user status. AshAuthentication's password strategy generates a `:sign_in_with_password` action -- add a preparation or change that checks status:

```elixir
# In User resource actions block
action :deactivate, :struct do
  constraints instance_of: __MODULE__
  run fn input, context ->
    user = input.arguments[:user] || raise "user required"
    # Update status to deactivated
    # Revoke all tokens for this user
  end
end

# Or simpler: update action
update :deactivate do
  change set_attribute(:status, :deactivated)
  # Add a change that revokes tokens
end
```

For blocking deactivated users from signing in, add a validation/change to the sign_in preparation that checks `status == :active`.

### Anti-Patterns to Avoid
- **Raw Ecto for user creation:** NEVER use `Repo.insert!` -- always Ash actions, even in seeds and mix tasks
- **Business logic in LiveView:** Keep role checks and deactivation logic in Ash policies/actions, not LiveView handlers
- **Custom session management:** Do NOT build custom session/token logic -- AshAuthentication handles this completely
- **Exposing user existence:** Never return different errors for "email not found" vs "wrong password" -- always "Invalid email or password"
- **Skipping policies on admin actions:** Every action must have a policy, including admin-only ones per CVE-2025-48043

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Password hashing | Custom bcrypt wrapper | AshAuthentication.BcryptProvider | Handles salt generation, timing-safe comparison, configurable rounds |
| Session management | Custom Plug.Session + token logic | AshAuthentication.Phoenix plugs + LiveSession | Handles cookie signing, token validation, LiveView mount, subject resolution |
| Sign-in/sign-out flow | Custom controller + manual session manipulation | auth_routes + sign_out_route macros + AuthController | Handles CSRF, token exchange, session cleanup |
| Token revocation | Custom token table + manual queries | AshAuthentication.TokenResource | Handles token lifecycle, revocation lists, expiry |
| LiveView auth state | Manual session reading in mount | ash_authentication_live_session + on_mount hooks | Handles subject loading, assign propagation, nested LiveView compat |
| Password validation | Custom regex/length checks | AshAuthentication strategy + Ash validations | Consistent with Ash action error handling |

**Key insight:** AshAuthentication is specifically designed for Ash resources -- it integrates with the action/policy/changeset pipeline. Building custom auth bypasses this integration and creates a parallel auth system that must be maintained separately.

## Common Pitfalls

### Pitfall 1: Forgetting to Disable Self-Registration
**What goes wrong:** AshAuthentication's password strategy enables registration by default, allowing anyone to create accounts
**Why it happens:** Default `registration_enabled?: true`
**How to avoid:** Set `registration_enabled? false` on the password strategy; create a separate admin-only `:create_user` action
**Warning signs:** A `/register` route exists or the sign-in page shows a registration form

### Pitfall 2: Not Configuring Token Signing Secret
**What goes wrong:** App crashes or uses insecure default in production
**Why it happens:** Token signing requires a secret configured per environment
**How to avoid:** Set `ASTRAPLEX_TOKEN_SIGNING_SECRET` in runtime.exs; generate with `mix phx.gen.secret`
**Warning signs:** Auth works in dev but fails in prod

### Pitfall 3: Slow Tests Due to bcrypt Rounds
**What goes wrong:** Test suite becomes extremely slow
**Why it happens:** bcrypt default rounds (12) are deliberately slow for security
**How to avoid:** Add `config :bcrypt_elixir, log_rounds: 1` to `config/test.exs`
**Warning signs:** Tests involving user creation/login take seconds each

### Pitfall 4: Deactivated Users Remaining Logged In
**What goes wrong:** Admin deactivates a user but they continue using the app until their session expires
**Why it happens:** Session tokens remain valid even after status change
**How to avoid:** Revoke all tokens on deactivation; the on_mount hook should re-verify user status from the database
**Warning signs:** Deactivated users can continue accessing the app

### Pitfall 5: Policy Bypass via AshAuthenticationInteraction (CVE-2025-48043)
**What goes wrong:** Overly broad bypass policy allows unintended access
**Why it happens:** The `AshAuthenticationInteraction` bypass is needed for auth actions but can be too permissive if custom actions are not properly scoped
**How to avoid:** Write explicit policies for each custom action (create_user, deactivate, update_role, etc.); write negative authorization tests proving non-admin users CANNOT perform admin actions
**Warning signs:** Staff users can access admin routes or perform admin actions

### Pitfall 6: Missing load_from_session Plug
**What goes wrong:** current_user is nil in LiveViews even after login
**Why it happens:** The `:load_from_session` plug is not in the browser pipeline
**How to avoid:** Add `plug :load_from_session` to the browser pipeline after `:fetch_session`
**Warning signs:** Login succeeds but redirect to authenticated page shows no user

### Pitfall 7: Forgetting AshAuthentication.Supervisor
**What goes wrong:** Token validation and session management fail silently
**Why it happens:** AshAuthentication.Supervisor is not added to Application supervision tree
**How to avoid:** Add `{AshAuthentication.Supervisor, otp_app: :astraplex}` to Application children
**Warning signs:** Intermittent auth failures, token operations fail

## Code Examples

### Mix Task: Create Admin
```elixir
# lib/mix/tasks/astraplex.create_admin.ex
defmodule Mix.Tasks.Astraplex.CreateAdmin do
  @moduledoc "Creates an admin user. Usage: mix astraplex.create_admin email password"
  @shortdoc "Create an admin user"

  use Mix.Task

  @impl Mix.Task
  def run([email, password]) do
    Mix.Task.run("app.start")

    case Astraplex.Accounts.create_user(%{
      email: email,
      password: password,
      password_confirmation: password,
      role: :admin
    }, authorize?: false) do
      {:ok, user} ->
        Mix.shell().info("Admin created: #{user.email}")
      {:error, error} ->
        Mix.shell().error("Failed: #{inspect(error)}")
        exit({:shutdown, 1})
    end
  end

  def run(_) do
    Mix.shell().error("Usage: mix astraplex.create_admin <email> <password>")
    exit({:shutdown, 1})
  end
end
```

### Test Helper: Register and Log In User
```elixir
# In test/support/conn_case.ex
def register_and_log_in_user(%{conn: conn} = context, opts \\ []) do
  role = Keyword.get(opts, :role, :staff)
  email = Keyword.get(opts, :email, "user-#{System.unique_integer()}@example.com")
  password = "ValidPassword123!"

  {:ok, hashed} = AshAuthentication.BcryptProvider.hash(password)

  user = Ash.Seed.seed!(Astraplex.Accounts.User, %{
    email: email,
    hashed_password: hashed,
    role: role,
    status: :active
  })

  strategy = AshAuthentication.Info.strategy!(Astraplex.Accounts.User, :password)

  {:ok, signed_in_user} =
    AshAuthentication.Strategy.action(strategy, :sign_in, %{
      email: email,
      password: password
    })

  conn =
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(signed_in_user)

  Map.merge(context, %{conn: conn, user: user})
end
```

### Seeds for Development
```elixir
# priv/repo/seeds.exs
if Mix.env() == :dev do
  {:ok, hashed} = AshAuthentication.BcryptProvider.hash("admin123!")

  Ash.Seed.seed!(Astraplex.Accounts.User, %{
    email: "admin@astraplex.dev",
    hashed_password: hashed,
    role: :admin,
    status: :active
  })

  for i <- 1..5 do
    {:ok, hashed} = AshAuthentication.BcryptProvider.hash("staff123!")
    Ash.Seed.seed!(Astraplex.Accounts.User, %{
      email: "staff#{i}@astraplex.dev",
      hashed_password: hashed,
      role: :staff,
      status: :active
    })
  end
end
```

### Negative Authorization Test (CVE-2025-48043)
```elixir
# test/astraplex/accounts/user_authorization_test.exs
describe "staff cannot perform admin actions" do
  test "staff cannot create users" do
    staff = create_user(role: :staff)

    assert {:error, %Ash.Error.Forbidden{}} =
      Astraplex.Accounts.create_user(
        %{email: "new@test.com", password: "password123!", role: :staff},
        actor: staff
      )
  end

  test "staff cannot deactivate users" do
    staff = create_user(role: :staff)
    target = create_user(role: :staff)

    assert {:error, %Ash.Error.Forbidden{}} =
      Astraplex.Accounts.deactivate(target, actor: staff)
  end

  test "deactivated users cannot sign in" do
    user = create_user(status: :deactivated)
    strategy = AshAuthentication.Info.strategy!(Astraplex.Accounts.User, :password)

    assert {:error, _} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{
        email: user.email,
        password: "password123!"
      })
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ash_authentication ~> 3.x | ash_authentication ~> 4.x | 2024 | Major version bump; API changes in strategy configuration |
| Manual LiveView auth hooks | ash_authentication_live_session macro | ash_authentication_phoenix 2.x | Automatic session-to-socket propagation |
| Custom token tables | AshAuthentication.TokenResource extension | Built-in | Declarative token management |
| phx.gen.auth | AshAuthentication for Ash projects | N/A | phx.gen.auth generates raw Ecto code; incompatible with Ash's action pipeline |

**Deprecated/outdated:**
- `AshAuthentication.Plug` direct usage: Use `AshAuthentication.Phoenix.Plug` helpers and router macros instead
- `api` option in AshPhoenix.Form: Renamed to `domain` in Ash 3.x

## Open Questions

1. **Deactivation + Token Revocation Implementation**
   - What we know: AshAuthentication supports token revocation; the TokenResource stores tokens
   - What's unclear: Exact API for revoking all tokens for a specific user on deactivation
   - Recommendation: Investigate `AshAuthentication.TokenResource` actions for bulk token revocation during implementation; may need a custom action that queries and revokes all tokens for a user_id

2. **Sign-in Action Status Check**
   - What we know: Need to block deactivated users at sign-in time
   - What's unclear: Whether to use a preparation on the generated sign_in action or a custom change
   - Recommendation: Add a `sign_in_preparation` or wrap the sign_in action with a pre-check; test during implementation

3. **MCP Endpoint Auth**
   - What we know: /mcp scope currently has no auth (deferred from Phase 2)
   - What's unclear: Whether to add token-based auth to MCP now or defer further
   - Recommendation: Defer to a later phase -- Phase 3 scope is already substantial; MCP auth requires API token management which is a separate concern

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | test/test_helper.exs |
| Quick run command | `mix test test/astraplex/accounts/` |
| Full suite command | `mix test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | Admin creates user with email/password | integration | `mix test test/astraplex/accounts/user_test.exs -x` | Wave 0 |
| FOUND-02 | Admin assigns Admin/Staff role | integration | `mix test test/astraplex/accounts/user_test.exs -x` | Wave 0 |
| FOUND-03 | Admin deactivates user, user cannot login, messages preserved | integration | `mix test test/astraplex/accounts/user_test.exs -x` | Wave 0 |
| FOUND-04 | User logs in with email/password | integration | `mix test test/astraplex/accounts/user_test.exs -x` | Wave 0 |
| FOUND-05 | Session persists across refresh | e2e | `mix test test/e2e/auth_test.exs --include e2e -x` | Wave 0 |
| FOUND-06 | User logs out from any page | integration + e2e | `mix test test/astraplex_web/live/auth_live_test.exs -x` | Wave 0 |
| CVE-NEG | Staff cannot access admin actions | integration | `mix test test/astraplex/accounts/user_authorization_test.exs -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/astraplex/accounts/`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before /gsd:verify-work

### Wave 0 Gaps
- [ ] `test/astraplex/accounts/user_test.exs` -- covers FOUND-01, FOUND-02, FOUND-03, FOUND-04
- [ ] `test/astraplex/accounts/user_authorization_test.exs` -- negative auth tests (CVE-2025-48043)
- [ ] `test/astraplex_web/live/auth_live_test.exs` -- sign-in/sign-out LiveView flows
- [ ] `test/astraplex_web/live/admin/user_list_live_test.exs` -- admin user management UI
- [ ] `test/e2e/auth_test.exs` -- session persistence, full login/logout flow
- [ ] Smokestack factory for User in `test/support/factory.ex`
- [ ] Auth test helpers (register_and_log_in_user) in `test/support/conn_case.ex`
- [ ] `config :bcrypt_elixir, log_rounds: 1` in `config/test.exs`
- [ ] Token signing secret in `config/test.exs` and `config/dev.exs`

## Sources

### Primary (HIGH confidence)
- [hexdocs ash_authentication](https://hexdocs.pm/ash_authentication/) - Get started guide, password strategy DSL, testing guide, token configuration
- [hexdocs ash_authentication_phoenix](https://hexdocs.pm/ash_authentication_phoenix/) - Router macros, LiveSession, sign_in_route, overrides
- Existing codebase: router.ex, system domain, repo.ex, mix.exs, test support files

### Secondary (MEDIUM confidence)
- [Alembic blog: Customising Ash Authentication with Phoenix LiveView](https://alembic.com.au/blog/customising-ash-authentication-with-phoenix-liveview) - Custom sign-in LiveView pattern with AshPhoenix.Form
- [Elixir Forum: Ash user management](https://elixirforum.com/t/ash-user-management-how-to-create-an-administrator-that-can-perform-basic-crud-operations-on-users/59538) - Admin CRUD patterns
- [hex.pm ash_authentication](https://hex.pm/packages/ash_authentication) - Version 4.13.7 confirmed as latest stable
- [hex.pm ash_authentication_phoenix](https://hex.pm/packages/ash_authentication_phoenix) - Version 2.15.0 confirmed as latest stable

### Tertiary (LOW confidence)
- Password hashing comparison (multiple web sources) - Argon2 vs bcrypt recommendations; used only for discretion decision, not critical path

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - AshAuthentication is the official Ash auth extension; versions verified on hex.pm
- Architecture: HIGH - Patterns verified against official docs and existing codebase conventions
- Pitfalls: HIGH - Testing guide explicitly documents bcrypt rounds issue; CVE flagged in project STATE.md
- Custom sign-in LiveView: MEDIUM - Pattern from blog post, not official tutorial; core API (AshPhoenix.Form) is official

**Research date:** 2026-03-09
**Valid until:** 2026-04-09 (stable ecosystem, 30-day validity)
