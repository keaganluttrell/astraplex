# Phase 4: Channels - Research

**Researched:** 2026-03-10
**Domain:** Ash Framework resource modeling, relationships, policies, PubSub real-time, LiveView integration
**Confidence:** HIGH

## Summary

Phase 4 introduces the Messaging domain with three new Ash resources (Channel, Membership, Message) and their corresponding LiveView interfaces. The core challenge is modeling the polymorphic Message resource that will serve both channels (Phase 4) and conversations (Phase 5) while keeping the domain clean. Ash Framework 3.x provides all necessary primitives: `belongs_to`/`has_many` relationships, `relates_to_actor_via` policy checks for membership-based authorization, `Ash.Notifier.PubSub` for real-time broadcasts, and `AshPhoenix.Form` for form handling. The existing codebase has established clear patterns (shell layouts, drawers/modals, AshPhoenix.Form, Smokestack factories) that this phase extends.

The polymorphic message design uses two nullable `belongs_to` columns (`channel_id` and `conversation_id`) with a custom validation ensuring exactly one is set. This is simpler and more Ash-idiomatic than Ash.Type.Union which is designed for polymorphic resource types, not polymorphic parent references. The sidebar_group component needs to be extended to accept real channel data and render linked items with `#` prefix.

**Primary recommendation:** Use standard Ash `belongs_to`/`has_many` relationships with nullable foreign keys for polymorphic message ownership; use `Ash.Notifier.PubSub` for real-time message delivery; use `relates_to_actor_via(:memberships)` and `expr(exists(...))` for membership-based policies.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Phase 4 includes basic plain text message sending in channels (not deferred to Phase 6)
- Messages appear in real-time for all channel members via Phoenix PubSub (basic broadcast)
- Phase 6 adds rich text, mentions, reactions, threading, and optimistic UI on top
- Message resource designed as polymorphic from the start (belongs to channel OR conversation via polymorphic reference)
- Phase 5 (DMs/Groups) reuses the same Message resource -- no refactor needed
- All resources live in the Messaging domain: `lib/astraplex/messaging/`
- Resources: Channel, Membership, Message (polymorphic)
- Full channel management at `/admin/channels` (list, create, edit, archive)
- Sidebar '+' button for quick channel creation (admin-only) -- opens a drawer
- Creation form: name (required) + description (optional) -- members added separately after creation
- Channel names must be unique (case-insensitive) -- validation error on duplicate
- Same drawer component for create and edit modes
- Settings/gear icon in chat header (admin-only) opens a drawer with name, description, and archive button
- Drawers for edit forms, modals for destructive confirmations (archive = modal confirm)
- Channel settings drawer includes a 'Members' section with current member list and 'Add Members' button
- User picker: searchable list of all active users not already in channel, supports multi-select
- Member removal: remove icon per row, confirmation modal ("Remove [Name] from #channel?")
- Creator is NOT auto-added as a member -- admin must explicitly add themselves
- All channel members can see the member list (read-only for staff, add/remove for admin only)
- Channels displayed with `#` prefix, sorted alphabetically
- Active channel highlighted in sidebar
- Archived channels hidden from sidebar -- accessible via admin page only
- UUID-based routing: `/channels/:id` (not slug-based)
- Sidebar updates in real-time via PubSub when user is added to a new channel
- Unread badge markup included as hidden placeholder -- Phase 7 wires real counts

### Claude's Discretion
- Polymorphic message association pattern (research best Ash approach)
- Channel list pagination on admin page
- Message pagination/infinite scroll in chat view
- PubSub topic naming convention
- Drawer component implementation details
- User picker search/filter implementation
- Empty state content for channels with no messages

### Deferred Ideas (OUT OF SCOPE)
- Unread message tracking and badge counts -- Phase 7 (PRES-03)
- Rich text, mentions, reactions, threading -- Phase 6 (Messaging Core)
- Channel search/filtering -- v2 (SRCH-01/02)
- Channel reordering / pinning -- future phase
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CHAN-01 | Admin can create a channel with a name and description | Channel resource with `:create` action, ci_string name with unique identity, AshPhoenix.Form for creation drawer |
| CHAN-02 | Admin can invite users to a channel | Membership resource with `:create` action, manage_relationship or direct Ash.create for adding members |
| CHAN-03 | Admin can remove users from a channel | Membership `:destroy` action with admin policy, confirmation modal pattern from Phase 3 |
| CHAN-04 | User can view list of channels they are a member of | Channel read action with `filter expr(exists(memberships, user_id == ^actor(:id)))` policy, sidebar integration |
| CHAN-05 | New channel members can see full message history | Messages loaded via Channel relationship, no time-gating -- all messages visible to all members |
| CHAN-06 | Admin can archive a channel (no new messages, history preserved) | Channel `:archive` update action setting status to :archived, Message create policy checks channel not archived |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ash | ~> 3.0 (3.19.x current) | Resource modeling, actions, policies | Already in project, all data access through Ash |
| AshPostgres | ~> 2.0 | PostgreSQL data layer, migrations | Already in project, generates migrations with `mix ash_postgres.generate_migrations` |
| AshPhoenix | ~> 2.0 | Form handling, LiveView integration | Already in project, `AshPhoenix.Form` used in UserListLive |
| Phoenix.PubSub | (bundled) | Real-time message broadcast | Already available via Phoenix, Ash.Notifier.PubSub integrates directly |
| DaisyUIComponents | ~> 0.9 | UI components (drawer, modal, table, form_input) | Already in project, established pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Smokestack | ~> 0.9 | Test factories for Channel, Membership, Message | All integration tests |
| Ash.Notifier.PubSub | (built into Ash) | Declarative PubSub publishing on resource actions | Message and Membership create/destroy broadcasting |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Nullable FK polymorphic | Ash.Type.Union | Union is for polymorphic resource *types* (e.g., SavingsAccount vs CheckingAccount), not polymorphic parent references. Two nullable FKs is simpler and standard for "belongs to A or B" |
| AshPhoenix.LiveView.keep_live | Manual PubSub subscribe/handle_info | keep_live reruns the entire query on every notification. Manual subscribe gives more control for chat UX (append message to list vs full reload). Use manual for messages, keep_live acceptable for sidebar channel list. |
| Offset pagination | Keyset pagination | Keyset is better for real-time data (no shifting). Use for messages. Offset fine for admin channel list. |

**Installation:**
No new dependencies needed. All libraries already in `mix.exs`.

## Architecture Patterns

### Recommended Project Structure
```
lib/astraplex/
  messaging/
    messaging.ex           # Ash Domain module
    channel.ex             # Channel resource
    membership.ex          # Membership (join) resource
    message.ex             # Message resource (polymorphic)
lib/astraplex_web/
  live/
    channel_live.ex        # Channel chat view
    admin/
      channel_list_live.ex # Admin channel management
  components/
    messaging.ex           # Messaging-specific components (message bubble, member list, user picker)
```

### Pattern 1: Polymorphic Message via Nullable Foreign Keys
**What:** Message has both `channel_id` and `conversation_id` as nullable belongs_to columns. A custom validation ensures exactly one is set.
**When to use:** When a resource can belong to one of N parent types and you want standard Ash relationships on all sides.
**Example:**
```elixir
# Source: Ash relationships docs + common Ecto polymorphic pattern
defmodule Astraplex.Messaging.Message do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    attribute(:body, :string, allow_nil?: false, public?: true)
    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :channel, Astraplex.Messaging.Channel, allow_nil?: true
    belongs_to :conversation, Astraplex.Messaging.Conversation, allow_nil?: true  # Phase 5
    belongs_to :sender, Astraplex.Accounts.User, allow_nil?: false
  end

  validations do
    # Ensure exactly one parent is set
    validate fn changeset, _context ->
      channel_id = Ash.Changeset.get_attribute(changeset, :channel_id)
      conversation_id = Ash.Changeset.get_attribute(changeset, :conversation_id)

      case {channel_id, conversation_id} do
        {nil, nil} -> {:error, field: :channel_id, message: "must belong to a channel or conversation"}
        {_, nil} -> :ok
        {nil, _} -> :ok
        {_, _} -> {:error, field: :channel_id, message: "cannot belong to both a channel and conversation"}
      end
    end
  end
end
```

**Note for Phase 4:** The `conversation_id` column should exist in the schema from day one but the Conversation resource itself is Phase 5. During Phase 4, only `channel_id` is used. The validation can initially just require `channel_id` to be set, then be updated in Phase 5 to allow either.

### Pattern 2: Membership-Based Policy Authorization
**What:** Use `relates_to_actor_via` and `expr(exists(...))` for policies that check channel membership.
**When to use:** Any action where access depends on the actor being a member of the channel.
**Example:**
```elixir
# Channel resource policies
policies do
  # Admin can do everything
  policy action_type([:create, :update, :destroy]) do
    authorize_if expr(^actor(:role) == :admin)
  end

  # Members can read channels they belong to
  policy action_type(:read) do
    authorize_if expr(^actor(:role) == :admin)
    authorize_if relates_to_actor_via(:members)
  end
end

# Message resource policies
policies do
  # Members can create messages in non-archived channels
  policy action(:send_message) do
    authorize_if expr(
      exists(channel.memberships, user_id == ^actor(:id)) and
      channel.status != :archived
    )
  end

  # Members can read messages in channels they belong to
  policy action_type(:read) do
    authorize_if expr(exists(channel.memberships, user_id == ^actor(:id)))
  end
end
```

### Pattern 3: PubSub Notifier for Real-Time Updates
**What:** Declarative PubSub publishing on Ash resource actions using `Ash.Notifier.PubSub`.
**When to use:** When resource changes need to be broadcast to LiveView subscribers.
**Example:**
```elixir
# Message resource PubSub config
pub_sub do
  module AstraplexWeb.Endpoint
  prefix "channel"

  # Broadcast new messages to channel topic
  publish :send_message, ["messages", :channel_id]
end

# Membership resource PubSub config
pub_sub do
  module AstraplexWeb.Endpoint
  prefix "membership"

  # Notify when member added/removed (for sidebar updates)
  publish :create, ["changed", :user_id]
  publish :destroy, ["changed", :user_id]
end
```

```elixir
# LiveView subscribing to channel messages
def mount(%{"id" => channel_id}, _session, socket) do
  if connected?(socket) do
    AstraplexWeb.Endpoint.subscribe("channel:messages:#{channel_id}")
    # Subscribe to membership changes for sidebar
    AstraplexWeb.Endpoint.subscribe("membership:changed:#{socket.assigns.current_user.id}")
  end
  # ...
end

def handle_info(%{topic: "channel:messages:" <> _channel_id, payload: %Ash.Notifier.Notification{data: message}}, socket) do
  {:noreply, stream_insert(socket, :messages, message)}
end
```

### Pattern 4: Sidebar Channel List via PubSub
**What:** The sidebar_group component receives real channel data and updates in real-time when membership changes.
**When to use:** For the channels section in the sidebar layout.
**Example:**
```elixir
# In the LiveView mount, load user's channels
channels = Astraplex.Messaging.list_user_channels!(actor: current_user)
socket = assign(socket, :channels, channels)

# sidebar_group component extended to accept items
attr :title, :string, required: true
attr :items, :list, default: []
attr :placeholder, :string, required: true
attr :current_id, :string, default: nil
slot :add_button

defp sidebar_group(assigns) do
  ~H"""
  <details open class="group px-2">
    <summary class="...">
      {@title}
      {render_slot(@add_button)}
      <.icon name="hero-chevron-down-micro" class="..." />
    </summary>
    <ul :if={@items == []} class="menu menu-sm pl-2">
      <li class="disabled">
        <span class="text-base-content/40 text-xs">{@placeholder}</span>
      </li>
    </ul>
    <ul :if={@items != []} class="menu menu-sm pl-2">
      <li :for={item <- @items}>
        <.link navigate={item.url} class={item.id == @current_id && "menu-active"}>
          {item.label}
          <span class="badge badge-sm badge-primary hidden"></span>  <%!-- Phase 7 unread placeholder --%>
        </.link>
      </li>
    </ul>
  </details>
  """
end
```

### Anti-Patterns to Avoid
- **Direct Ecto queries in LiveView:** All data access MUST go through Ash actions. Never use `Repo.all(from c in "channels", ...)`.
- **Business logic in LiveView handle_event:** Delegate to Ash actions. The LiveView just calls `Ash.create(...)` or `Ash.update!(...)`.
- **Storing channel name in URL:** Use UUID-based routing `/channels/:id`. Channel names can change; IDs are stable.
- **Auto-adding creator as member:** CONTEXT.md explicitly states creator is NOT auto-added. Admin must explicitly add themselves.
- **Skipping archived check in message creation:** Messages MUST be blocked on archived channels at the policy/validation level, not just UI.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form handling | Custom changeset wrappers | AshPhoenix.Form.for_create/for_update | Handles validation, error display, nested data |
| Real-time broadcast | Manual Phoenix.PubSub.broadcast calls | Ash.Notifier.PubSub declarative config | Automatic on action completion, transactional safety |
| Authorization checks | if current_user.role == :admin | Ash policies with authorize_if | Centralized, testable, consistent enforcement |
| Migration generation | Hand-written migrations | `mix ash_postgres.generate_migrations` | Ash snapshots ensure schema matches resource definition |
| Case-insensitive uniqueness | Custom DB constraint + downcase | `:ci_string` type + Ash identity | Already proven in User.email, citext extension loaded |

**Key insight:** Ash's declarative DSL handles 90% of the plumbing (migrations, validations, authorization, notifications). Hand-rolling any of these creates maintenance burden and diverges from established patterns.

## Common Pitfalls

### Pitfall 1: Forgetting to Register Messaging Domain
**What goes wrong:** Ash cannot find resources; actions fail with "no domain" errors.
**Why it happens:** New domain created but not added to `config :astraplex, ash_domains:` list.
**How to avoid:** Add `Astraplex.Messaging` to `config.exs` ash_domains list immediately when creating the domain module.
**Warning signs:** `** (Ash.Error.Framework.DomainNotFound)` at runtime.

### Pitfall 2: Policy CVE (CVE-2025-48043) -- Missing Negative Authorization Tests
**What goes wrong:** Authorization bypass not caught by tests.
**Why it happens:** Only testing that authorized users CAN access resources, not that unauthorized users CANNOT.
**How to avoid:** Write negative tests for every policy: staff cannot create channels, non-members cannot read channel messages, etc.
**Warning signs:** Tests only cover happy path authorization.

### Pitfall 3: PubSub Topics Not Matching Between Publisher and Subscriber
**What goes wrong:** Messages broadcast but LiveView never receives them.
**Why it happens:** Topic template in `pub_sub do` block produces different string than what LiveView subscribes to.
**How to avoid:** Use consistent topic naming convention. The Ash PubSub prefix + publish template produces `"prefix:segment1:segment2"` with `:` delimiter by default. Verify by logging topics.
**Warning signs:** Messages appear on refresh but not in real-time.

### Pitfall 4: N+1 Queries in Channel List / Message List
**What goes wrong:** Slow page load when loading channels with member counts or messages with sender info.
**Why it happens:** Relationships not eagerly loaded.
**How to avoid:** Use `Ash.load!` or include `load: [...]` in the read action to preload relationships.
**Warning signs:** Slow queries in dev logs, multiple SELECT statements per page load.

### Pitfall 5: Sidebar Not Updating When Membership Changes
**What goes wrong:** User added to channel but sidebar doesn't show it until page refresh.
**Why it happens:** Sidebar channel list loaded once on mount, no PubSub subscription for membership changes.
**How to avoid:** Subscribe to user-specific membership topic. On membership create/destroy notification, re-query user's channel list.
**Warning signs:** Sidebar only updates on navigation.

### Pitfall 6: Archived Channel Leaking New Messages
**What goes wrong:** Users can still send messages to archived channels via API/direct action call.
**Why it happens:** Archive check only in UI (disabled button) but not in Ash policy/validation.
**How to avoid:** Add validation on Message `:send_message` action that checks `channel.status != :archived`. Use policy expression or a custom validation.
**Warning signs:** Messages appear in archived channels.

## Code Examples

### Channel Resource Definition
```elixir
# Source: Ash relationships docs + project conventions
defmodule Astraplex.Messaging.Channel do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)

    attribute :name, :ci_string,
      allow_nil?: false,
      public?: true,
      constraints: [max_length: 80, trim?: true]

    attribute :description, :string,
      allow_nil?: true,
      public?: true,
      constraints: [max_length: 500]

    attribute :status, :atom,
      constraints: [one_of: [:active, :archived]],
      default: :active,
      allow_nil?: false,
      public?: true

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity :unique_name, [:name]
  end

  relationships do
    has_many :memberships, Astraplex.Messaging.Membership
    has_many :messages, Astraplex.Messaging.Message

    many_to_many :members, Astraplex.Accounts.User do
      through Astraplex.Messaging.Membership
      source_attribute_on_join_resource :channel_id
      destination_attribute_on_join_resource :user_id
    end
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :description]
    end

    update :update do
      accept [:name, :description]
    end

    update :archive do
      accept []
      change set_attribute(:status, :archived)
    end

    read :list_for_user do
      description "List active channels the current user is a member of."
      filter expr(status == :active and exists(memberships, user_id == ^actor(:id)))
      prepare build(sort: [name: :asc])
    end
  end

  policies do
    policy action([:create, :update, :archive]) do
      authorize_if expr(^actor(:role) == :admin)
    end

    policy action(:read) do
      authorize_if expr(^actor(:role) == :admin)
      authorize_if expr(exists(memberships, user_id == ^actor(:id)))
    end

    policy action(:list_for_user) do
      authorize_if always()  # Filter handles scoping
    end
  end

  postgres do
    table "channels"
    repo Astraplex.Repo
  end
end
```

### Membership Resource Definition
```elixir
defmodule Astraplex.Messaging.Membership do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :channel, Astraplex.Messaging.Channel, allow_nil?: false
    belongs_to :user, Astraplex.Accounts.User, allow_nil?: false
  end

  identities do
    identity :unique_membership, [:channel_id, :user_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:channel_id, :user_id]
    end
  end

  policies do
    policy action([:create, :destroy]) do
      authorize_if expr(^actor(:role) == :admin)
    end

    policy action(:read) do
      # Members can read membership list for channels they belong to
      authorize_if expr(^actor(:role) == :admin)
      authorize_if expr(exists(channel.memberships, user_id == ^actor(:id)))
    end
  end

  pub_sub do
    module AstraplexWeb.Endpoint
    prefix "membership"

    publish :create, ["changed", :user_id]
    publish :destroy, ["changed", :user_id]
  end

  postgres do
    table "memberships"
    repo Astraplex.Repo
  end
end
```

### Messaging Domain Module
```elixir
defmodule Astraplex.Messaging do
  @moduledoc "Messaging domain for channels, conversations, and messages."

  use Ash.Domain, otp_app: :astraplex

  resources do
    resource Astraplex.Messaging.Channel
    resource Astraplex.Messaging.Membership
    resource Astraplex.Messaging.Message
  end
end
```

### PubSub Subscribe Pattern in LiveView
```elixir
# In ChannelLive
def mount(%{"id" => channel_id}, _session, socket) do
  channel = Astraplex.Messaging.Channel
    |> Ash.get!(channel_id, actor: socket.assigns.current_user, load: [:members])

  messages = load_messages(channel, socket.assigns.current_user)

  if connected?(socket) do
    AstraplexWeb.Endpoint.subscribe("channel:messages:#{channel_id}")
  end

  {:ok,
    socket
    |> assign(:channel, channel)
    |> stream(:messages, messages)}
end

def handle_info(
  %{topic: "channel:messages:" <> _, payload: %Ash.Notifier.Notification{data: message}},
  socket
) do
  message = Ash.load!(message, [:sender], actor: socket.assigns.current_user)
  {:noreply, stream_insert(socket, :messages, message, at: -1)}
end
```

### Smokestack Factory for Messaging Resources
```elixir
# In test/support/factory.ex - extend existing factory
factory Astraplex.Messaging.Channel do
  attribute(:name, fn -> "channel-#{System.unique_integer([:positive])}" end)
  attribute(:description, fn -> "Test channel" end)
  attribute(:status, fn -> :active end)
end

factory Astraplex.Messaging.Membership do
  # channel_id and user_id set via relate option or direct attribute
end

factory Astraplex.Messaging.Message do
  attribute(:body, fn -> "Test message #{System.unique_integer([:positive])}" end)
  # sender_id and channel_id set via relate option or direct attribute
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ecto polymorphic associations via abstract tables | Ash nullable FK pattern with validation | Ash 3.x | Simpler, fully supported by Ash policies and relationships |
| Manual PubSub.broadcast in action callbacks | Ash.Notifier.PubSub declarative config | Ash 3.0 | Automatic, transactional, no manual broadcast code |
| Phoenix.Component assigns for list data | LiveView streams (stream/stream_insert) | Phoenix LV 0.20+ | Memory efficient for large message lists, DOM-diffing optimized |

**Deprecated/outdated:**
- `Ash.Notifier.PubSub` module path has not changed in Ash 3.x but the configuration DSL has stabilized. Use `pub_sub do` block in resource definition.
- `AshPhoenix.LiveView.keep_live` exists but is acknowledged to "simply rerun the query" on every notification. For chat messages, manual stream_insert is preferred.

## Open Questions

1. **Conversation resource column in Phase 4**
   - What we know: Message needs `conversation_id` column for Phase 5 reuse. The Conversation resource does not exist yet.
   - What's unclear: Whether to add the column now (with no resource) or add it in Phase 5.
   - Recommendation: Add the `conversation_id` nullable column now in the Message resource definition but leave it unused. The migration will create it, and Phase 5 just adds the Conversation resource and relationship. This avoids a migration-only change in Phase 5.

2. **Message pagination strategy**
   - What we know: Keyset pagination is best for real-time data. Chat apps typically load newest messages first and paginate backwards.
   - What's unclear: Whether Ash keyset pagination handles reverse-chronological well.
   - Recommendation: Use keyset pagination with `sort: [inserted_at: :desc]` and reverse the list in the LiveView for display. Start with loading last 50 messages. Infinite scroll can use `stream` with `phx-hook` for scroll detection.

3. **Sidebar data loading architecture**
   - What we know: Every LiveView currently calls shell functions directly in render. The sidebar needs channel data.
   - What's unclear: Whether to load channels in each LiveView mount or use a shared on_mount hook.
   - Recommendation: Create a new on_mount hook `:load_user_channels` in LiveAuth that loads channels and assigns them to socket. This keeps LiveViews clean and ensures consistent sidebar data. Alternatively, load in each LiveView's mount since the shell already requires current_user.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/astraplex/messaging/` |
| Full suite command | `mix test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHAN-01 | Admin creates channel with name/description | integration | `mix test test/astraplex/messaging/channel_test.exs -x` | No -- Wave 0 |
| CHAN-01 | Channel name uniqueness (case-insensitive) | integration | `mix test test/astraplex/messaging/channel_test.exs -x` | No -- Wave 0 |
| CHAN-01 | Staff cannot create channels (negative auth) | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-02 | Admin invites user to channel | integration | `mix test test/astraplex/messaging/membership_test.exs -x` | No -- Wave 0 |
| CHAN-02 | Duplicate membership rejected | integration | `mix test test/astraplex/messaging/membership_test.exs -x` | No -- Wave 0 |
| CHAN-02 | Staff cannot invite (negative auth) | integration | `mix test test/astraplex/messaging/membership_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-03 | Admin removes user from channel | integration | `mix test test/astraplex/messaging/membership_test.exs -x` | No -- Wave 0 |
| CHAN-03 | Staff cannot remove (negative auth) | integration | `mix test test/astraplex/messaging/membership_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-04 | User sees only their channels | integration | `mix test test/astraplex/messaging/channel_test.exs -x` | No -- Wave 0 |
| CHAN-04 | Non-member cannot read channel (negative auth) | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-05 | New member sees full message history | integration | `mix test test/astraplex/messaging/message_test.exs -x` | No -- Wave 0 |
| CHAN-05 | Non-member cannot read messages (negative auth) | integration | `mix test test/astraplex/messaging/message_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-06 | Admin archives channel | integration | `mix test test/astraplex/messaging/channel_test.exs -x` | No -- Wave 0 |
| CHAN-06 | Cannot send message to archived channel | integration | `mix test test/astraplex/messaging/message_test.exs -x` | No -- Wave 0 |
| CHAN-06 | Staff cannot archive (negative auth) | integration | `mix test test/astraplex/messaging/channel_authorization_test.exs -x` | No -- Wave 0 |
| CHAN-06 | Archived channel history still readable | integration | `mix test test/astraplex/messaging/message_test.exs -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/astraplex/messaging/`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/astraplex/messaging/channel_test.exs` -- covers CHAN-01, CHAN-04, CHAN-06
- [ ] `test/astraplex/messaging/channel_authorization_test.exs` -- covers CHAN-01, CHAN-04, CHAN-06 negative auth
- [ ] `test/astraplex/messaging/membership_test.exs` -- covers CHAN-02, CHAN-03
- [ ] `test/astraplex/messaging/membership_authorization_test.exs` -- covers CHAN-02, CHAN-03 negative auth
- [ ] `test/astraplex/messaging/message_test.exs` -- covers CHAN-05, CHAN-06 message blocking
- [ ] `test/astraplex/messaging/message_authorization_test.exs` -- covers CHAN-05 negative auth
- [ ] Factory additions in `test/support/factory.ex` -- Channel, Membership, Message factories

## Sources

### Primary (HIGH confidence)
- [Ash Relationships docs (v3.19.2)](https://hexdocs.pm/ash/relationships.html) - belongs_to, has_many, many_to_many patterns
- [Ash Polymorphic Relationships guide](https://hexdocs.pm/ash/polymorphic-relationships.html) - Union type approach (evaluated, not recommended for this use case)
- [Ash Policies docs (v3.16.0)](https://hexdocs.pm/ash/policies.html) - relates_to_actor_via, expr-based checks
- [Ash.Notifier.PubSub docs](https://hexdocs.pm/ash/Ash.Notifier.PubSub.html) - Declarative pub_sub config, topic templates, broadcast types
- [AshPhoenix.LiveView docs (v2.3.20)](https://hexdocs.pm/ash_phoenix/AshPhoenix.LiveView.html) - keep_live, handle_live patterns
- [Ash.CiString docs](https://hexdocs.pm/ash/Ash.CiString.html) - Case-insensitive string type for channel names

### Secondary (MEDIUM confidence)
- [Ash Notifiers guide (v3.16.0)](https://hexdocs.pm/ash/notifiers.html) - Notifier lifecycle, transaction behavior
- [Elixir Forum: Smokestack factory with belongs_to](https://elixirforum.com/t/smokestack-factory-with-belongs-to-relationship/58558) - Factory patterns with relationships
- [Smokestack docs (v0.9.2)](https://hexdocs.pm/smokestack/Smokestack.html) - Build/relate options

### Tertiary (LOW confidence)
- None -- all findings verified against official Ash docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all libraries already in project and proven in Phases 1-3
- Architecture: HIGH - Ash resource patterns well-documented, polymorphic FK approach verified in official docs
- Pitfalls: HIGH - based on actual project history (policy CVE, PubSub topics) and official docs
- Policies: HIGH - relates_to_actor_via and expr(exists(...)) verified in official Ash policy docs
- PubSub: HIGH - Ash.Notifier.PubSub configuration verified in official docs with code examples

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (stable -- Ash 3.x API is mature)
