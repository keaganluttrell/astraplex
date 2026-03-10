# Phase 5: Conversations - Research

**Researched:** 2026-03-10
**Domain:** Ash Framework resources, Phoenix LiveView real-time messaging, PubSub patterns
**Confidence:** HIGH

## Summary

Phase 5 introduces a unified Conversation resource into the existing Messaging domain. The core pattern is well-established: Conversation mirrors Channel's structure (resource + join table + messages), but with key differences -- conversations are created by any user (not admin-only), membership is fixed at creation, and uniqueness is enforced per member set. The existing Message resource gains a polymorphic `conversation_id` alongside the existing `channel_id`.

The LiveView and PubSub patterns from Phase 4 (ChannelLive) transfer directly. The primary new complexity is: (1) lazy creation -- conversations are not persisted until the first message is sent, requiring temporary client-side state management; (2) enforcing uniqueness across member sets (sorted user ID arrays); and (3) replacing the two placeholder sidebar groups ("Direct Messages" and "Groups") with a single "DMs" section populated from real data.

**Primary recommendation:** Build Conversation and ConversationMembership as Ash resources following the exact patterns from Channel/Membership, add conversation_id to Message, create a ConversationLive mirroring ChannelLive, and update the sidebar to show a unified "DMs" section with real-time PubSub updates.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Single Conversation resource -- no separate DM/Group types
- No type field; member count determines behavior: 2 members = DM, 3+ = group
- 1:1 DMs are unique per user pair -- starting a DM with someone you've already messaged reopens the existing conversation
- Group conversations are also unique per exact member set -- same people = same conversation
- Members are fixed at creation -- no adding or removing members after the fact
- No leaving conversations (DMs or groups) -- all conversations are permanent
- GRP-04 ("User can leave a group conversation") explicitly descoped from v1
- Sidebar '+' button in the DMs section opens a drawer with a user picker
- Multi-select user picker: pick 1+ users. 1 user = DM, 2+ = group
- If a conversation with the exact same member set already exists, silently navigate to it (no error or toast)
- Lazy creation: conversation is NOT persisted until the first message is sent -- no empty conversations in sidebar
- User picker shows all active users (reuses pattern from channel member picker with client-side email filtering)
- Single "DMs" sidebar section replaces separate "Direct Messages" and "Groups" sections
- Sorted by most recent activity (newest messages at top)
- Sidebar updates in real-time via PubSub when new conversation is created (lazy -- on first message)
- Reuses chat_layout component from Phase 4
- Chat header shows conversation name + people icon to open member list drawer (read-only)
- Plain text messaging with real-time PubSub delivery (same pattern as channels)
- Message display: messages start at top of scroll area; once full, view pins to bottom
- Conversations visible only to participants -- no admin visibility into conversations they're not part of
- Admins can only see conversations they are a member of, same as staff
- Reuses the existing Message resource -- adds conversation_id (allow_nil: true, polymorphic with channel_id)
- PubSub broadcast pattern reused from channels with conversation-scoped topics

### Claude's Discretion
- Conversation PubSub topic naming convention
- User picker search/filter implementation details
- Stacked avatar vs group icon for multi-person conversations in sidebar
- Member list drawer layout and styling
- Empty state for DMs section when no conversations exist
- Exact scroll behavior implementation (ScrollBottom hook adaptation)
- How lazy creation handles the pre-persist state in the chat view

### Deferred Ideas (OUT OF SCOPE)
- Leaving group conversations (GRP-04) -- descoped from v1 entirely
- Adding members to existing conversations -- future enhancement
- Conversation naming for groups -- not in v1, display member names only
- Admin visibility into all conversations -- explicitly rejected for privacy
- Conversation search -- v2 (SRCH-01/02)
- Muting conversations -- Phase 7 (PRES-05)
- Unread badges on conversations -- Phase 7 (PRES-03)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DM-01 | User can start a 1:1 direct message with any other user | Conversation resource with find_or_create pattern; user picker drawer; lazy creation on first message send |
| DM-02 | User can view list of their DM conversations | `list_for_user` action on Conversation filtered by membership + member count == 2; sidebar "DMs" section |
| DM-03 | DM conversations are visible only to the two participants | Policy: authorize only if actor is a member via `exists(conversation_memberships, user_id == ^actor(:id))` |
| GRP-01 | User can create an ad-hoc group conversation by selecting 2+ users | Same user picker with 2+ selections; same lazy creation pattern; member count >= 3 |
| GRP-02 | User can view list of their group conversations | Same `list_for_user` action; sidebar shows both DMs and groups in unified "DMs" section |
| GRP-03 | Group conversations are visible only to participants | Same membership-based policy as DM-03 -- no distinction needed |
| GRP-04 | User can leave a group conversation | DESCOPED from v1 per CONTEXT.md decision |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ash Framework | 3.x | Conversation + ConversationMembership resources, policies, actions | Already used for Channel, Message, Membership -- same patterns |
| AshPostgres | 2.x | Data layer with migrations | Existing data layer for all resources |
| AshPhoenix | 2.x | Form handling for message sending | Used in ChannelLive for message forms |
| Phoenix PubSub | 2.x | Real-time conversation message broadcast | Established pattern from channel messaging |
| Phoenix LiveView | 1.x | ConversationLive view with streams | Established pattern from ChannelLive |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| DaisyUIComponents | existing | Drawer, modal, form, badge components | All UI rendering |
| Smokestack | existing | Test factories for Conversation, ConversationMembership | All integration tests |

### Alternatives Considered
None -- all decisions are locked. The stack is the same as Phase 4.

## Architecture Patterns

### New Resources in Messaging Domain
```
lib/astraplex/messaging/
  conversation.ex              # Conversation resource
  conversation_membership.ex   # ConversationMembership join resource
  checks/can_send_to_conversation.ex  # SimpleCheck for conversation message policy
```

### New LiveView and Components
```
lib/astraplex_web/
  live/conversation_live.ex    # Conversation chat view (mirrors ChannelLive)
  live/new_conversation_live.ex  # (Optional) or handle via drawer in sidebar
```

### Pattern 1: Unified Conversation Resource

**What:** A single `Conversation` Ash resource -- no type field. Member count determines DM vs group behavior at the display layer only.

**When to use:** All conversation creation and querying.

**Key attributes:**
```elixir
# Conversation resource
attributes do
  uuid_primary_key(:id)
  create_timestamp(:inserted_at)
  update_timestamp(:updated_at)
end

relationships do
  has_many :conversation_memberships, Astraplex.Messaging.ConversationMembership
  has_many :messages, Astraplex.Messaging.Message

  many_to_many :members, Astraplex.Accounts.User do
    through(Astraplex.Messaging.ConversationMembership)
    source_attribute_on_join_resource(:conversation_id)
    destination_attribute_on_join_resource(:user_id)
  end
end
```

**Key design note:** Conversation has NO name or description attribute. Display names are derived from member names at the view layer.

### Pattern 2: Member-Set Uniqueness

**What:** Enforce that no two conversations have the same exact set of members. This is the trickiest data modeling challenge.

**Approach -- sorted member_hash:**
```elixir
# On Conversation resource
attribute(:member_hash, :string, allow_nil?: false)

identities do
  identity(:unique_member_set, [:member_hash])
end
```

The `member_hash` is computed as a deterministic hash of sorted member UUIDs. When creating a conversation, sort all member UUIDs alphabetically, join them, and hash (or just use the joined string if the set is small). This enables a unique constraint and fast lookup.

**Alternative -- sorted UUID string:** For small member sets (typical for DMs and small groups), the sorted concatenation of UUIDs can serve directly as the identity value without hashing, making debugging easier:
```elixir
# For members [uuid_a, uuid_b, uuid_c] sorted:
member_hash = Enum.sort([uuid_a, uuid_b, uuid_c]) |> Enum.join(",")
```

**Why not a DB constraint on the join table?** PostgreSQL cannot enforce set-uniqueness across rows in a join table. A computed hash on the parent record is the standard approach.

### Pattern 3: Lazy Creation (Conversation + First Message in One Action)

**What:** Conversations are not persisted until the first message is sent. The chat view must handle an "unsaved" state.

**Recommended implementation:**

1. User picks members in the drawer, clicks "Start Conversation"
2. Check if a conversation with that member set already exists (by member_hash)
3. If exists: navigate to `/dm/{id}`
4. If not: navigate to `/dm/new?members=uuid1,uuid2,...` (temporary URL)
5. ConversationLive mounts with either a real conversation ID or a `members` param
6. When user sends first message, create Conversation + ConversationMemberships + Message in a single custom action
7. After creation, `push_patch` to `/dm/{id}` to update URL
8. PubSub broadcast notifies all members to update their sidebars

**Custom Ash action for atomic creation:**
```elixir
# On Conversation resource
create :create_with_message do
  accept([])
  argument(:member_ids, {:array, :uuid}, allow_nil?: false)
  argument(:body, :string, allow_nil?: false)

  change fn changeset, context ->
    member_ids = Ash.Changeset.get_argument(changeset, :member_ids)
    actor_id = context.actor.id
    all_ids = Enum.uniq([actor_id | member_ids]) |> Enum.sort()
    member_hash = Enum.join(all_ids, ",")
    Ash.Changeset.force_change_attribute(changeset, :member_hash, member_hash)
  end
end
```

After creation, memberships and the first message are created in separate steps (or use an `after_action` hook to keep it atomic).

### Pattern 4: Conversation-Scoped PubSub

**What:** Messages in conversations broadcast on conversation-scoped topics, mirroring the channel pattern.

**Recommended topic naming:**
```elixir
# On Message resource pub_sub block (extended)
pub_sub do
  module(AstraplexWeb.Endpoint)
  prefix("channel")

  publish(:send_message, ["messages", :channel_id])
  publish(:send_conversation_message, ["messages", :conversation_id])
end
```

Or use a separate prefix for clarity:
```elixir
# Separate conversation pub_sub prefix
# Topic: "conversation:messages:{conversation_id}"
```

**Recommendation:** Use prefix `"conversation"` with `publish(:send_conversation_message, ["messages", :conversation_id])` to produce topics like `"conversation:messages:{uuid}"`. This keeps channel and conversation topics cleanly separated.

**Sidebar update PubSub:** When a conversation is first created (with first message), broadcast to each member's personal topic: `"user:conversations:{user_id}"`. Each LiveView subscribes to this topic to refresh the sidebar conversation list.

### Pattern 5: Polymorphic Message Resource

**What:** Message gains `conversation_id` alongside `channel_id`. Exactly one must be present per message.

```elixir
# Message resource updates
relationships do
  belongs_to :channel, Astraplex.Messaging.Channel, allow_nil?: true, public?: true
  belongs_to :conversation, Astraplex.Messaging.Conversation, allow_nil?: true, public?: true
  belongs_to :sender, Astraplex.Accounts.User, allow_nil?: false
end

actions do
  create :send_message do
    accept([:body, :channel_id])
    change(relate_actor(:sender))
    validate(present(:channel_id))
  end

  create :send_conversation_message do
    accept([:body, :conversation_id])
    change(relate_actor(:sender))
    validate(present(:conversation_id))
  end
end
```

**Separate actions** (not one polymorphic action) keeps policies clean -- `send_message` checks channel membership, `send_conversation_message` checks conversation membership.

### Pattern 6: Sidebar Data Flow

**What:** Replace the two placeholder sidebar groups with a single "DMs" section populated with real conversation data.

**Changes to shell layouts:**
```elixir
# admin_shell and staff_shell gain a conversations attr
attr :conversations, :list, default: []
attr :current_conversation_id, :string, default: nil
```

**Sidebar group for DMs:**
```elixir
<.sidebar_group
  title="DMs"
  placeholder="(No conversations yet)"
  items={@conversations}
  current_id={@current_conversation_id}
>
  <:add_button>
    <button phx-click="open_new_conversation" class="btn btn-ghost btn-xs">
      <.icon name="hero-plus" class="size-3" />
    </button>
  </:add_button>
</.sidebar_group>
```

**Sidebar item format for conversations:**
```elixir
# DM (2 members): show other person's email
# Group (3+ members): show "Alice, Bob +1"
%{
  id: to_string(conversation.id),
  label: conversation_display_name(conversation, current_user),
  url: ~p"/dm/#{conversation.id}"
}
```

### Anti-Patterns to Avoid
- **Separate DM and Group resources:** Decision explicitly locks a unified model. Do not create two tables.
- **Type/kind field on Conversation:** Member count is the only distinction. Adding a type field creates synchronization burden.
- **Raw Ecto for uniqueness check:** Use Ash actions with the member_hash identity. Never bypass Ash.
- **Eager conversation creation:** Conversations must NOT be persisted until the first message. Empty conversations should never exist in the database.
- **Admin bypass on conversation access:** Admins have NO special access to conversations they are not members of. Policies must treat admin and staff identically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Member-set uniqueness | Custom DB trigger or application-level lock | Sorted member_hash + Ash identity constraint | Deterministic, race-condition-safe via DB unique index |
| Real-time message delivery | WebSocket channels or polling | Ash PubSub notifier + Phoenix PubSub subscribe | Established pattern from Phase 4 channels |
| Form handling | Manual changeset/params processing | AshPhoenix.Form | Consistent with all other forms in the app |
| Conversation member display | Complex SQL joins in LiveView | Ash.load!([:members]) on conversation | Ash handles eager loading correctly |
| Sidebar conversation list | Raw query with joins | Ash read action with `exists` filter | Matches Channel's `list_for_user` pattern exactly |

## Common Pitfalls

### Pitfall 1: Race Condition on Lazy Creation
**What goes wrong:** Two participants send the first message simultaneously, creating duplicate conversations.
**Why it happens:** Without proper uniqueness enforcement, concurrent requests can both pass the "does it exist?" check.
**How to avoid:** The `member_hash` unique identity on Conversation ensures only one conversation per member set. Use `Ash.create` with error handling -- if uniqueness violation, fetch the existing conversation and attach the message to it.
**Warning signs:** Duplicate conversations appearing in sidebar for the same member set.

### Pitfall 2: Message Policy Scope Leak
**What goes wrong:** Messages from conversations leak into channel read queries or vice versa.
**Why it happens:** The current Message read policy checks `exists(channel.memberships, ...)` which returns no results for conversation messages (channel_id is nil).
**How to avoid:** Update Message read policy to authorize if actor is a member of EITHER the channel OR the conversation:
```elixir
policy action(:read) do
  authorize_if(expr(exists(channel.memberships, user_id == ^actor(:id))))
  authorize_if(expr(exists(conversation.conversation_memberships, user_id == ^actor(:id))))
end
```
**Warning signs:** Conversation messages not appearing for members, or appearing for non-members.

### Pitfall 3: Admin Read Policy on Messages
**What goes wrong:** The current Message read policy has `authorize_if(expr(^actor(:role) == :admin))` which would let admins read ALL conversation messages.
**Why it happens:** The Phase 4 policy assumed admin visibility was appropriate. Phase 5 explicitly rejects admin bypass for conversations.
**How to avoid:** Remove the blanket admin bypass from Message read policy. Admin should only see messages in channels/conversations they are a member of. This is a BREAKING CHANGE to the existing policy that must be handled carefully -- admin channel access may need to go through channel membership rather than role.
**Warning signs:** Admin seeing conversation messages they shouldn't have access to.

### Pitfall 4: N+1 on Sidebar Conversation Loading
**What goes wrong:** Loading conversation display names requires loading members for each conversation.
**Why it happens:** Display name is derived from member list, not stored on the conversation.
**How to avoid:** Use `Ash.read!(..., load: [:members])` in the list action, or add a calculation for display name that loads members efficiently.
**Warning signs:** Slow sidebar rendering as conversation count grows.

### Pitfall 5: Incorrect PubSub Topic for Sidebar Updates
**What goes wrong:** New conversations don't appear in other members' sidebars in real-time.
**Why it happens:** Only subscribing to conversation message topics, not to a "new conversation created" topic.
**How to avoid:** When a conversation is created (with first message), broadcast to each member's personal topic. Each LiveView subscribes to `"user:conversations:{user_id}"` on mount.
**Warning signs:** Need to refresh page to see new conversations.

### Pitfall 6: Lazy Creation URL State
**What goes wrong:** User refreshes the page on `/dm/new?members=...` and loses context, or bookmarks an invalid URL.
**Why it happens:** The pre-persist state exists only in the LiveView process.
**How to avoid:** The `/dm/new?members=uuid1,uuid2` URL encodes enough state to reconstruct the view on refresh. On mount, parse members from params, check if conversation exists, and render accordingly. After first message, `push_patch` to the real conversation URL.
**Warning signs:** Blank page or error on refresh of new conversation view.

## Code Examples

### Conversation Resource Structure
```elixir
# Source: Derived from existing Channel resource pattern
defmodule Astraplex.Messaging.Conversation do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    attribute(:member_hash, :string, allow_nil?: false)
    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_member_set, [:member_hash])
  end

  relationships do
    has_many :conversation_memberships, Astraplex.Messaging.ConversationMembership
    has_many :messages, Astraplex.Messaging.Message

    many_to_many :members, Astraplex.Accounts.User do
      through(Astraplex.Messaging.ConversationMembership)
      source_attribute_on_join_resource(:conversation_id)
      destination_attribute_on_join_resource(:user_id)
    end
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:member_hash])
    end

    read :list_for_user do
      filter(expr(exists(conversation_memberships, user_id == ^actor(:id))))
      prepare(build(sort: [updated_at: :desc], load: [:members]))
    end

    read :find_by_member_hash do
      get_by([:member_hash])
    end
  end

  policies do
    policy action(:create) do
      authorize_if(actor_present())
    end

    policy action(:read) do
      authorize_if(expr(exists(conversation_memberships, user_id == ^actor(:id))))
    end

    policy action(:list_for_user) do
      authorize_if(always())
    end

    policy action(:find_by_member_hash) do
      authorize_if(actor_present())
    end
  end

  postgres do
    table("conversations")
    repo(Astraplex.Repo)
  end
end
```

### ConversationMembership Resource
```elixir
# Source: Mirrors existing Membership resource pattern
defmodule Astraplex.Messaging.ConversationMembership do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :conversation, Astraplex.Messaging.Conversation, allow_nil?: false
    belongs_to :user, Astraplex.Accounts.User, allow_nil?: false
  end

  identities do
    identity(:unique_conversation_membership, [:conversation_id, :user_id])
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:conversation_id, :user_id])
    end
  end

  policies do
    policy action(:create) do
      authorize_if(actor_present())
    end

    policy action(:read) do
      authorize_if(expr(exists(conversation.conversation_memberships, user_id == ^actor(:id))))
    end
  end

  postgres do
    table("conversation_memberships")
    repo(Astraplex.Repo)
  end
end
```

### CanSendToConversation Check
```elixir
# Source: Mirrors existing CanSendToChannel check
defmodule Astraplex.Messaging.Checks.CanSendToConversation do
  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_options) do
    "actor is a member of the target conversation"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _options) do
    conversation_id = Ash.Changeset.get_attribute(changeset, :conversation_id)

    case conversation_id do
      nil -> false
      conversation_id ->
        Astraplex.Messaging.ConversationMembership
        |> Ash.Query.filter(conversation_id == ^conversation_id and user_id == ^actor.id)
        |> Ash.read(authorize?: false)
        |> case do
          {:ok, memberships} -> memberships != []
          _ -> false
        end
    end
  end
end
```

### Conversation Display Name Helper
```elixir
# In a component or helper module
defp conversation_display_name(conversation, current_user) do
  other_members =
    conversation.members
    |> Enum.reject(&(&1.id == current_user.id))

  case other_members do
    [single] ->
      to_string(single.email)

    [first, second] ->
      "#{short_name(first)}, #{short_name(second)}"

    [first, second | rest] ->
      "#{short_name(first)}, #{short_name(second)} +#{length(rest)}"

    [] ->
      "Conversation"
  end
end

defp short_name(user) do
  user.email |> to_string() |> String.split("@") |> hd()
end
```

### Member Hash Computation
```elixir
defp compute_member_hash(member_ids) do
  member_ids
  |> Enum.map(&to_string/1)
  |> Enum.sort()
  |> Enum.join(",")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate DM/Group tables | Unified conversation with member_hash | Phase 5 design decision | Simpler data model, consistent policies |
| Admin sees all messages | Membership-only access for conversations | Phase 5 privacy decision | Must update existing Message read policy |
| Channel-only messaging | Polymorphic channel_id/conversation_id on Message | Phase 5 | Message resource gains second relationship |

## Open Questions

1. **Message read policy admin bypass removal**
   - What we know: Current policy allows admins to read all messages. Phase 5 requires conversations be member-only.
   - What's unclear: Should admin bypass remain for channel messages specifically, or should it be removed entirely? Currently admins are always channel members via explicit membership.
   - Recommendation: Keep admin bypass for channel messages (admin manages channels) but ensure conversation messages only authorize via membership. Use two separate policy conditions checking channel vs conversation membership.

2. **Conversation updated_at for sorting**
   - What we know: Sidebar sorts by most recent activity (newest messages at top).
   - What's unclear: Whether to update `updated_at` on Conversation when a new message is sent, or compute last message timestamp at query time.
   - Recommendation: Touch `updated_at` on Conversation after each message send (via after_action hook on send_conversation_message). This is simpler than computing from messages and enables direct sort.

3. **ScrollBottom hook "start at top" adaptation**
   - What we know: Current ScrollBottom hook always pins to bottom. User wants messages to start at top and only pin to bottom once the scroll area is full.
   - What's unclear: Whether this requires a new hook or modification to existing.
   - Recommendation: The existing `chat_layout` already uses `flex flex-col justify-end min-h-full` which naturally pushes content to the bottom when there are few messages. The ScrollBottom hook handles the auto-scroll on new messages. This may already work correctly -- verify during implementation.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | test/test_helper.exs |
| Quick run command | `mix test test/astraplex/messaging/conversation_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DM-01 | Create 1:1 conversation with first message | integration | `mix test test/astraplex/messaging/conversation_test.exs -x` | Wave 0 |
| DM-02 | List user's DM conversations | integration | `mix test test/astraplex/messaging/conversation_test.exs -x` | Wave 0 |
| DM-03 | Non-participant cannot see DM | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs -x` | Wave 0 |
| GRP-01 | Create group conversation (3+ members) | integration | `mix test test/astraplex/messaging/conversation_test.exs -x` | Wave 0 |
| GRP-02 | List user's group conversations | integration | `mix test test/astraplex/messaging/conversation_test.exs -x` | Wave 0 |
| GRP-03 | Non-participant cannot see group | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs -x` | Wave 0 |
| GRP-04 | Leave group conversation | N/A | N/A -- descoped | N/A |
| CROSS | Member hash uniqueness (same members = same conversation) | integration | `mix test test/astraplex/messaging/conversation_test.exs -x` | Wave 0 |
| CROSS | Admin cannot see non-member conversations | integration | `mix test test/astraplex/messaging/conversation_authorization_test.exs -x` | Wave 0 |
| CROSS | Send message to conversation | integration | `mix test test/astraplex/messaging/message_test.exs -x` | Extend existing |

### Sampling Rate
- **Per task commit:** `mix test test/astraplex/messaging/ -x`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/astraplex/messaging/conversation_test.exs` -- covers DM-01, DM-02, GRP-01, GRP-02, uniqueness
- [ ] `test/astraplex/messaging/conversation_authorization_test.exs` -- covers DM-03, GRP-03, admin restrictions
- [ ] `test/support/factory.ex` -- add Conversation and ConversationMembership factories
- [ ] Extend `test/astraplex/messaging/message_test.exs` -- covers send_conversation_message action
- [ ] Extend `test/astraplex/messaging/message_authorization_test.exs` -- covers conversation message policy

## Sources

### Primary (HIGH confidence)
- Existing codebase: `lib/astraplex/messaging/` -- Channel, Membership, Message resource patterns
- Existing codebase: `lib/astraplex_web/live/channel_live.ex` -- LiveView messaging pattern with streams + PubSub
- Existing codebase: `lib/astraplex_web/components/messaging.ex` -- user_picker, member_list, message_bubble components
- Existing codebase: `lib/astraplex_web/components/layouts.ex` -- chat_layout, sidebar_group, shell layouts
- Existing codebase: `test/astraplex/messaging/` -- test patterns with Smokestack factories
- CONTEXT.md locked decisions -- all architectural choices verified

### Secondary (MEDIUM confidence)
- Ash Framework patterns for SimpleCheck, pub_sub, identities -- verified against existing working code in codebase
- Member hash uniqueness approach -- standard pattern for set-uniqueness in relational databases

### Tertiary (LOW confidence)
- None -- all patterns are direct extensions of existing verified code

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- identical to Phase 4, no new libraries
- Architecture: HIGH -- all patterns mirror existing Channel/Membership/Message code
- Pitfalls: HIGH -- identified from code review of existing resource interactions
- Lazy creation: MEDIUM -- novel pattern not yet used in codebase, but well-understood LiveView state management

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (stable -- all patterns are internal to the project)
