---
status: resolved
trigger: "User cannot navigate to an archived channel. There is no way to see it in the UI."
created: 2026-03-10T00:00:00Z
updated: 2026-03-10T00:00:00Z
---

## Current Focus

hypothesis: Multiple compounding issues make archived channels inaccessible
test: Code review of sidebar, channel live, admin list, and channel resource
expecting: Identify all filtering/UI gaps
next_action: Report diagnosis

## Symptoms

expected: User should be able to navigate to an archived channel at /channels/:id and see message history with a warning banner and no input form.
actual: Archived channels are invisible in the UI. No navigation path exists to reach them.
errors: None (silent inaccessibility)
reproduction: Archive a channel via admin, then try to access it as any user
started: Since archiving was implemented

## Eliminated

(none needed -- root cause found on first pass)

## Evidence

- timestamp: 2026-03-10
  checked: Channel resource list_for_user action (channel.ex line 68-72)
  found: Filter is `status == :active and exists(memberships, user_id == ^actor(:id))` -- explicitly excludes archived channels
  implication: Sidebar will never show archived channels for any user

- timestamp: 2026-03-10
  checked: ChannelLive.load_sidebar_channels (channel_live.ex line 170-176)
  found: Uses `Ash.read!(action: :list_for_user)` which filters to active-only
  implication: Sidebar in channel view never shows archived channels

- timestamp: 2026-03-10
  checked: ChannelLive.mount (channel_live.ex line 7-29)
  found: Uses `Ash.get!(Channel, channel_id, actor: current_user)` with default :read action
  implication: Direct URL /channels/:id for archived channel WILL work for admins (read policy allows admin) and for members (read policy allows members). The channel page itself is accessible via direct URL.

- timestamp: 2026-03-10
  checked: ChannelLive.channel_content (channel_live.ex line 100-121)
  found: Already handles archived status -- shows warning banner and hides input form when `@channel.status == :archived`
  implication: The archived channel VIEW already works correctly. Only the NAVIGATION is missing.

- timestamp: 2026-03-10
  checked: Admin ChannelListLive.load_channels (channel_list_live.ex line 418-422)
  found: Uses default :read action with no status filter -- shows ALL channels including archived
  implication: Admin channel list table DOES show archived channels with "Archived" badge

- timestamp: 2026-03-10
  checked: Admin channel_table action column (channel_list_live.ex line 268-272)
  found: Links to `/admin/channels/:id` (settings drawer), NOT to `/channels/:id` (chat view)
  implication: Admin can see archived channels in list but cannot navigate to the chat view from there

- timestamp: 2026-03-10
  checked: Channel read policy (channel.ex line 80-83)
  found: read policy authorizes admins unconditionally AND members via `exists(memberships, user_id == ^actor(:id))`
  implication: The read policy does NOT filter by status, so archived channels are readable. Direct URL access works.

## Resolution

root_cause: |
  Three compounding gaps make archived channels inaccessible in the UI:

  1. **Sidebar filtering (primary cause):** The `list_for_user` action (channel.ex:68-72) filters `status == :active`, so archived channels never appear in the sidebar navigation.

  2. **No alternative navigation path for regular users:** There is no "archived channels" section, search, or other UI element that would let a non-admin user discover or navigate to an archived channel.

  3. **Admin list links to settings, not chat:** The admin channel list table (channel_list_live.ex:269) links to `/admin/channels/:id` (the settings drawer) rather than `/channels/:id` (the chat view). Even admins who can see archived channels in the list have no one-click path to the chat view.

  Importantly, the ChannelLive view itself (channel_live.ex:100-121) already handles archived channels correctly -- it shows the warning banner and hides the message input. The problem is purely navigational.

fix: (diagnosis only -- not applied)
verification: (diagnosis only)
files_changed: []
