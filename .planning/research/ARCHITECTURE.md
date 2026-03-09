# Architecture Patterns

**Domain:** Real-time internal messaging platform (multi-property)
**Researched:** 2026-03-09

## Recommended Architecture

### High-Level System View

```
                          Browser (LiveView Client)
                                   |
                            WebSocket (LiveView)
                                   |
                     +-------------+-------------+
                     |                           |
               LiveView Layer              Phoenix Presence
          (Chat, Sidebar, Thread)        (online/typing state)
                     |                           |
                     +--------+------------------+
                              |
                       Phoenix PubSub
                     (ephemeral broadcast)
                              |
              +---------------+---------------+
              |               |               |
        Ash Domains      Ash Notifiers     Oban Jobs
              |          (after commit)    (durable async)
              |               |               |
    +---------+---------+     |          +----+----+
    |    |    |    |     |    |          |         |
  Accts Msg Props Notif  |    |       Email    Push
    |    |    |    |     |    |
    +----+----+----+-----+    |
              |               |
         PostgreSQL      Phoenix PubSub
       (source of truth)  (fan-out delivery)
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Ash.Accounts** | Users, roles, authentication, property assignments | Properties (membership queries) |
| **Ash.Properties** | Property CRUD, staff-property membership | Accounts (user lookups) |
| **Ash.Messaging** | Channels, conversations, messages, threads, reactions, mentions, memberships | Properties (scoping), Accounts (authorization), PubSub (broadcast via notifier) |
| **Ash.Notifications** | Notification preferences, notification records, delivery orchestration | Messaging (triggered by message events), Oban (async delivery) |
| **Phoenix PubSub** | Ephemeral fan-out of real-time events to connected LiveViews | All LiveViews, Ash Notifiers |
| **Phoenix Presence** | Online/offline status, typing indicators per conversation | PubSub (underlying transport), LiveViews |
| **Oban** | Durable async jobs: email, push notifications, file processing | Notifications domain, external services |
| **LiveView Layer** | UI rendering, stream management, user interaction | PubSub (subscribe), Ash domains (read/write), Presence |

## Channel Scoping: Property-Local with Admin Cross-Property Override

**Recommendation: Property-scoped channels as the default, with explicit cross-property channels created by Admin only.**

This is the right call for Astraplex because:

1. **Staff mental model.** Staff are assigned to properties. Their daily work context is a property. Channels should match this mental model -- "Kitchen Team" belongs to the Downtown property, not floating in space.

2. **Authorization simplicity.** Property-scoped channels inherit property membership as the authorization boundary. If a staff member is assigned to Property A, they can see Property A channels. No complex ACL needed for the common case.

3. **Cross-property is a real need but an uncommon one.** Admin coordinating maintenance across properties, or sharing a policy update. This is the exception, not the rule. Model it as an explicit `scope` attribute on the channel.

4. **Implementation via Ash attribute-based multitenancy.** Use `property_id` as the tenant attribute on channels and messages. Cross-property channels use `global? true` with explicit membership checks.

### Data Model for Scoping

```elixir
# Channel resource
defmodule Astraplex.Messaging.Channel do
  use Ash.Resource, ...

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :description, :string
    attribute :property_id, :uuid  # nil for cross-property channels
    attribute :scope, :atom, constraints: [one_of: [:property, :cross_property]], default: :property
    timestamps()
  end

  multitenancy do
    strategy :attribute
    attribute :property_id
    global? true  # allows cross-property channels (property_id = nil)
  end
end
```

**Why not fully cross-property by default?** Because it forces every query, every authorization check, and every PubSub topic to handle "which properties can this user see?" -- a combinatorial explosion. Property-scoped keeps it simple. Cross-property channels are an explicit opt-in with explicit membership.

**Why not configurable per channel?** That IS the recommendation. The `scope` field makes it configurable. But the default is `:property`, and only Admin can create `:cross_property` channels.

**Confidence: HIGH** -- this pattern maps directly to Ash's attribute-based multitenancy with `global? true`, and matches how multi-location businesses actually communicate.

## Ash Domain Boundaries

### Accounts Domain

```
Astraplex.Accounts
  |-- User (resource)
  |     attributes: email, hashed_password, name, role (:admin/:staff), active?
  |     identities: unique email
  |
  |-- Token (resource)
  |     authentication token management
  |
  Actions exposed:
    - register_user (admin only)
    - deactivate_user
    - get_user_by_email
    - list_users_for_property
```

### Properties Domain

```
Astraplex.Properties
  |-- Property (resource)
  |     attributes: name, address, active?
  |
  |-- PropertyMembership (resource)
  |     attributes: user_id, property_id, joined_at
  |     join resource between User and Property
  |
  Actions exposed:
    - create_property
    - assign_user_to_property
    - remove_user_from_property
    - list_properties_for_user
    - list_users_for_property
```

### Messaging Domain

```
Astraplex.Messaging
  |-- Channel (resource)
  |     attributes: name, description, property_id, scope, created_by_id
  |     multitenancy: attribute :property_id, global? true
  |
  |-- ChannelMembership (resource)
  |     attributes: channel_id, user_id, muted?, joined_at
  |
  |-- Conversation (resource)  [DMs and group messages]
  |     attributes: type (:dm/:group), title (optional, for groups)
  |
  |-- ConversationParticipant (resource)
  |     attributes: conversation_id, user_id, muted?, joined_at
  |
  |-- Message (resource)
  |     attributes: body (rich text), sender_id, parent_id (for threads),
  |                 messageable_type (:channel/:conversation),
  |                 messageable_id, inserted_at
  |     immutable: no update actions
  |
  |-- Reaction (resource)
  |     attributes: message_id, user_id, emoji
  |
  |-- ReadReceipt (resource)
  |     attributes: message_id, user_id, read_at
  |
  |-- Mention (resource)
  |     attributes: message_id, user_id
  |
  Actions exposed:
    - create_channel (admin)
    - send_message
    - add_reaction / remove_reaction
    - mark_as_read
    - list_messages (cursor-paginated)
    - create_conversation (any user)
```

**Key design decision: Polymorphic messageable vs separate tables.**

Use a single `messages` table with `messageable_type` + `messageable_id`. Rationale:
- Messages have identical structure whether in channels or conversations
- Unread counts, search, and notification logic work uniformly
- Ash supports this via `Ash.Type.Union` or simple enum + UUID fields
- Avoids duplicating the entire message infrastructure

**Alternative considered:** Separate `channel_messages` and `conversation_messages` tables. Rejected because it doubles every message-related feature (threading, reactions, read receipts, search).

### Notifications Domain

```
Astraplex.Notifications
  |-- NotificationPreference (resource)
  |     attributes: user_id, channel_type (:in_app/:push/:email),
  |                 enabled?, quiet_hours_start, quiet_hours_end
  |
  |-- Notification (resource)
  |     attributes: user_id, type, title, body, read?, data (map),
  |                 source_type, source_id
  |
  Actions exposed:
    - create_notification
    - mark_read
    - list_unread
```

## Phoenix PubSub Topic Design

### Topic Hierarchy

```
Property-scoped channel messages:
  "messaging:channel:{channel_id}"

Conversation messages (DMs/groups):
  "messaging:conversation:{conversation_id}"

User-level events (unread counts, notifications):
  "user:{user_id}"

Typing indicators:
  "typing:channel:{channel_id}"
  "typing:conversation:{conversation_id}"

Presence (online/offline):
  "presence:property:{property_id}"    # who's online at this property
  "presence:global"                     # admin sees everyone
```

### Why This Structure

- **One topic per channel/conversation** -- subscribers receive only messages for conversations they are viewing. LiveView subscribes on mount, unsubscribes on navigation.
- **Separate typing topics** -- typing events are high-frequency and ephemeral. Separating them from message topics prevents unnecessary re-renders when only typing state changes.
- **User-level topic** -- sidebar unread badges update without subscribing to every channel. When a message is sent, broadcast to the channel topic AND to each member's user topic with an unread count delta.
- **Property-scoped presence** -- staff at the same property see each other's online status. Admin gets a global view.

### Broadcast Flow

```
User sends message
  |
  v
LiveView calls Ash action: Messaging.send_message(params)
  |
  v
Ash action: validates, persists to Postgres (in transaction)
  |
  v
Transaction commits
  |
  v
Ash.Notifier.PubSub fires (configured on Message resource):
  - Broadcasts to "messaging:channel:{channel_id}" or "messaging:conversation:{conv_id}"
  - Broadcasts to "user:{recipient_id}" for each member (unread count)
  |
  v
Oban job enqueued (in notifier or after_action):
  - Check notification preferences
  - Send push notification / email if user is offline
  |
  v
Connected LiveViews receive broadcast via handle_info:
  - stream_insert new message
  - Update unread counter in sidebar
```

### Ash PubSub Notifier Configuration

```elixir
defmodule Astraplex.Messaging.Message do
  use Ash.Resource,
    notifiers: [Ash.Notifier.PubSub]

  pub_sub do
    module AstraplexWeb.Endpoint
    prefix "messaging"

    publish :create, ["channel", :messageable_id],
      event: "new_message"

    publish :destroy, ["channel", :messageable_id],
      event: "message_deleted"
  end
end
```

**Confidence: HIGH** -- Ash.Notifier.PubSub is purpose-built for this exact pattern. Phoenix PubSub scales to thousands of topics trivially on a single node.

## Presence Architecture

### Online/Offline Status

```elixir
defmodule AstraplexWeb.Presence do
  use Phoenix.Presence,
    otp_app: :astraplex,
    pubsub_server: Astraplex.PubSub
end
```

Track users per property:

```elixir
# In LiveView mount, after auth:
for property <- current_user.properties do
  AstraplexWeb.Presence.track(
    self(),
    "presence:property:#{property.id}",
    current_user.id,
    %{name: current_user.name, online_at: System.system_time(:second)}
  )
end
```

### Typing Indicators

Typing indicators are purely ephemeral -- never persisted, never queued.

```elixir
# User starts typing -> LiveView sends event
def handle_event("typing_start", _, socket) do
  Phoenix.PubSub.broadcast(
    Astraplex.PubSub,
    "typing:channel:#{socket.assigns.channel_id}",
    {:typing, socket.assigns.current_user.id, true}
  )
  {:noreply, socket}
end

# Receiving side debounces and shows indicator
def handle_info({:typing, user_id, true}, socket) do
  # Add to typing users, set a timer to clear after 3 seconds
  {:noreply, assign(socket, typing_users: MapSet.put(socket.assigns.typing_users, user_id))}
end
```

**Pattern: Do NOT use Phoenix Presence for typing indicators.** Presence is designed for tracking process lifecycles (join/leave), not high-frequency ephemeral state. Use raw PubSub broadcasts with client-side debouncing and a 3-second timeout for typing indicators.

**Confidence: HIGH** -- this is the standard Phoenix community pattern.

## Message Storage Patterns

### Schema Design

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  body TEXT NOT NULL,                              -- rich text (stored as HTML or markdown)
  sender_id UUID NOT NULL REFERENCES users(id),
  parent_id UUID REFERENCES messages(id),          -- single-depth threading
  messageable_type VARCHAR NOT NULL,               -- 'channel' or 'conversation'
  messageable_id UUID NOT NULL,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT now()
  -- no updated_at: messages are immutable
);

CREATE INDEX idx_messages_messageable ON messages(messageable_type, messageable_id, inserted_at DESC);
CREATE INDEX idx_messages_parent ON messages(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_messages_sender ON messages(sender_id);
```

### Pagination Strategy

Use **keyset (cursor-based) pagination** on `inserted_at` + `id`. Ash supports this natively.

```elixir
# In the Message resource
read :list_for_channel do
  argument :channel_id, :uuid, allow_nil?: false
  argument :before_cursor, :string  # opaque cursor

  pagination do
    keyset? true
    default_limit 50
    max_page_size 100
  end

  filter expr(messageable_type == :channel and messageable_id == ^arg(:channel_id))
  sort inserted_at: :desc, id: :desc
end
```

**Why keyset over offset:** Messages are append-heavy. Offset pagination breaks when new messages arrive (page 2 shifts). Keyset pagination is stable: "give me 50 messages before this timestamp" always returns the same set regardless of new inserts.

### Unread Tracking

Two approaches, use both:

1. **ReadReceipt table** -- stores `(user_id, message_id, read_at)` for "seen by" display on individual messages.
2. **Last-read watermark** -- store `(user_id, channel_id, last_read_message_id)` on the membership record. Unread count = `COUNT(messages WHERE id > last_read_message_id)`. This is O(1) to check and avoids scanning all read receipts.

```elixir
# On ChannelMembership
attribute :last_read_message_id, :uuid
```

**Confidence: HIGH** -- watermark pattern is standard for chat unread counts (used by Slack, Discord). ReadReceipts supplement it for per-message "seen by" UI.

## LiveView Architecture

### Page Structure

```
AppLive (root layout, always mounted)
  |-- Sidebar (LiveComponent)
  |     |-- PropertySwitcher
  |     |-- ChannelList (per property)
  |     |-- ConversationList (DMs/groups)
  |     |-- UnreadBadges
  |
  |-- MainContent (live_render or LiveComponent, swapped on navigation)
  |     |-- ChannelView / ConversationView
  |           |-- MessageList (stream)
  |           |-- MessageComposer
  |           |-- ThreadPanel (slide-out)
  |           |-- PresenceList
  |
  |-- NotificationTray (LiveComponent)
```

### Key LiveView Patterns

**Streams for message lists.** Messages are stored client-side via LiveView streams. The socket carries zero message data after initial load. New messages arrive via PubSub and are inserted into the stream.

```elixir
def mount(%{"channel_id" => channel_id}, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(Astraplex.PubSub, "messaging:channel:#{channel_id}")
    Phoenix.PubSub.subscribe(Astraplex.PubSub, "typing:channel:#{channel_id}")
  end

  messages = Messaging.list_messages_for_channel(channel_id, page: [limit: 50])

  socket =
    socket
    |> assign(:channel_id, channel_id)
    |> stream(:messages, messages)

  {:ok, socket}
end

def handle_info(%{event: "new_message", payload: message}, socket) do
  {:noreply, stream_insert(socket, :messages, message)}
end
```

**Infinite scroll up for history.** Use a scroll hook that detects when the user scrolls to the top, then loads the next page via keyset cursor and prepends with `stream_insert(socket, :messages, older_messages, at: 0)`.

**Sidebar stays mounted.** The sidebar subscribes to `"user:#{user_id}"` and receives unread count updates. It never unmounts during navigation, so subscription is stable.

**Confidence: HIGH** -- LiveView streams are the documented, recommended approach for large collections. The Fly.io Phoenix Files article demonstrates this exact pattern.

## Suggested Build Order

Based on component dependencies:

```
Phase 1: Foundation
  Accounts domain (users, auth, roles)
  Properties domain (properties, memberships)
  Database schemas + migrations
  Basic LiveView shell with auth

Phase 2: Core Messaging
  Messaging domain (channels, messages -- property-scoped only)
  ChannelMembership
  PubSub topic structure + Ash notifiers
  LiveView: channel list, message list with streams, composer
  Keyset pagination for message history

Phase 3: Conversations & Threading
  DMs and group conversations
  Single-depth reply threading
  Polymorphic message rendering (channel + conversation)
  Thread panel UI

Phase 4: Presence & Real-Time Polish
  Phoenix Presence (online/offline)
  Typing indicators
  Unread counts (watermark pattern)
  Read receipts

Phase 5: Rich Messaging
  Reactions
  Mentions (with notification trigger)
  Rich text / markdown in messages
  File uploads (images inline)

Phase 6: Notifications & Admin
  Notification preferences
  In-app notifications
  Push notifications (Oban jobs)
  Email notifications (Oban jobs)
  Admin: channel management, user management, audit log
  Cross-property channels (admin-only)

Phase 7: Search & Polish
  Message search (Postgres full-text)
  Mute channels/conversations
  Browser push notifications
  Performance optimization
```

**Ordering rationale:**
- Accounts/Properties MUST come first -- everything depends on auth and property membership
- Core messaging before conversations because channels are simpler (no polymorphic complexity yet) and validate the PubSub/stream patterns
- Presence after messaging because it's additive polish, not a dependency
- Rich messaging after threading because reactions/mentions layer onto the message infrastructure
- Notifications last because they require all message types to exist
- Cross-property channels deferred to Phase 6 because they need the authorization model to be mature

## Scalability Considerations

| Concern | At 100 users | At 1K users | At 10K users |
|---------|--------------|-------------|--------------|
| PubSub | Single node, Phoenix default adapter | Single node still fine | Consider Redis adapter or clustering |
| Message volume | Single Postgres, no concerns | Partition by messageable_id if needed | Read replicas, archival strategy |
| Presence | Single Presence tracker | Still fine (CRDT-based, distributed) | Shard by property |
| LiveView processes | ~100 BEAM processes | ~1K processes, well within BEAM capacity | Monitor memory per process, ensure streams are used |
| File uploads | Local or S3 | S3 with CDN | S3 + CDN + presigned URLs |

**For the 100+ user target:** Phoenix's default PubSub adapter (pg2/distributed Erlang) handles this trivially on a single node. No Redis, no external dependencies needed. The BEAM was built for exactly this scale of concurrent connections.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Storing Messages in LiveView Assigns
**What:** Keeping all messages in `socket.assigns.messages` as a list
**Why bad:** Memory grows linearly per connected user. 1000 messages x 100 users = 100K message structs in memory.
**Instead:** Use LiveView streams. Messages live in the client DOM, not in server memory.

### Anti-Pattern 2: Broadcasting Full Message Structs
**What:** Broadcasting the entire Ash resource struct over PubSub
**Why bad:** Includes internal fields, loaded relationships, metadata. Wastes bandwidth and leaks implementation details.
**Instead:** Broadcast a minimal map: `%{id, body, sender_id, sender_name, inserted_at}`. Or broadcast just the ID and let each LiveView load what it needs (adds DB queries but keeps broadcasts tiny).

### Anti-Pattern 3: Using Phoenix Channels Alongside LiveView
**What:** Running both Phoenix Channels and LiveView for real-time features
**Why bad:** Two WebSocket connections per user. Duplicate auth logic. Confusing data flow.
**Instead:** LiveView + PubSub handles everything Channels would. One connection, one auth path.

### Anti-Pattern 4: Per-Message Read Receipt Queries for Unread Counts
**What:** `COUNT(*) FROM messages WHERE id NOT IN (SELECT message_id FROM read_receipts WHERE user_id = ?)`
**Why bad:** Scans grow with message volume. Becomes slow after thousands of messages.
**Instead:** Watermark pattern: `COUNT(*) FROM messages WHERE id > last_read_message_id AND channel_id = ?` with an index. O(unread count) not O(total messages).

### Anti-Pattern 5: Schema-Based Multitenancy for Properties
**What:** Creating a separate Postgres schema per property
**Why bad:** Properties are not strong isolation boundaries (staff belong to multiple properties, admins see everything, cross-property channels exist). Schema-per-tenant is for true SaaS isolation.
**Instead:** Attribute-based multitenancy with `property_id`. Simple, queryable, supports cross-property access.

## Sources

- [Ash Framework Multitenancy Docs (v3)](https://hexdocs.pm/ash/multitenancy.html) -- HIGH confidence
- [Ash Notifiers Documentation (v3)](https://hexdocs.pm/ash/notifiers.html) -- HIGH confidence
- [Mastering Multitenancy in Ash Framework -- Alembic](https://alembic.com.au/blog/multitenancy-in-ash-framework) -- HIGH confidence
- [Building a Chat App with LiveView Streams -- Fly.io Phoenix Files](https://fly.io/phoenix-files/building-a-chat-app-with-liveview-streams/) -- HIGH confidence
- [Phoenix PubSub v2.2.0 Docs](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) -- HIGH confidence
- [Phoenix Presence Docs](https://hexdocs.pm/phoenix/presence.html) -- HIGH confidence
- [Elixir Forum: Chat Room Architecture with LiveView](https://elixirforum.com/t/how-to-design-chat-room-architecture-using-liveview-without-channel/66502) -- MEDIUM confidence
- [LiveView with PubSub -- Elixir School](https://elixirschool.com/blog/live-view-with-pub-sub) -- MEDIUM confidence
- [Domains and Resources in Ash -- AppSignal Blog](https://blog.appsignal.com/2026/01/13/domains-and-resources-in-ash-for-elixir.html) -- MEDIUM confidence
- [Paginator: Cursor-based pagination for Ecto](https://github.com/duffelhq/paginator) -- MEDIUM confidence (Ash has built-in keyset pagination)
