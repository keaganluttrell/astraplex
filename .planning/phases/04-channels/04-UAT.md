---
status: diagnosed
phase: 04-channels
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md]
started: 2026-03-10T22:00:00Z
updated: 2026-03-10T22:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Admin Channel List Page
expected: Navigate to /admin/channels as an admin user. You should see a table listing all channels with their name, status, and member count.
result: pass

### 2. Create a New Channel
expected: On /admin/channels, click a "New Channel" button. A drawer slides in from the right with a form. Fill in channel name and description, submit. The new channel appears in the list.
result: pass

### 3. Edit Channel Details
expected: Click a channel's settings/gear icon to open the settings drawer. Edit the channel name or description. Save changes. Updated details reflect in the list.
result: pass

### 4. Add Members to Channel
expected: In the channel settings drawer, find the members section. Use the user picker to search for users by email. Select and add members. They appear in the member list.
result: pass

### 5. Remove a Member from Channel
expected: In the channel settings drawer member list, click remove on a member. A confirmation modal appears. Confirm removal. The member disappears from the list.
result: pass

### 6. Archive a Channel
expected: In the channel settings drawer, find a danger zone section. Click archive. A confirmation modal appears. Confirm. The channel status changes to archived.
result: pass

### 7. Sidebar Shows User's Channels
expected: As a staff or admin user who is a member of channels, the sidebar shows those channels with # prefix, sorted alphabetically. The current channel is highlighted.
result: pass

### 8. Channel Chat View
expected: Click a channel in the sidebar or navigate to /channels/:id. You see the channel name in a header, message history (up to 50 messages), and a message input at the bottom. Messages are anchored to the bottom of the view.
result: pass

### 9. Send a Message
expected: Type a message in the input and press Enter or click send. The message appears in the chat immediately with your name/avatar. The input clears after sending.
result: pass

### 10. Real-Time Message Delivery
expected: Open the same channel in two browser tabs (different users). Send a message from one tab. The message appears in the other tab in real-time without refreshing.
result: pass

### 11. Admin Gear Icon in Chat
expected: As an admin, the channel chat header shows a gear icon linking to /admin/channels/:id. As a staff user, the gear icon does NOT appear.
result: pass

### 12. Archived Channel Read-Only
expected: Navigate to an archived channel. You see the message history and a warning banner indicating the channel is archived. There is no message input form.
result: issue
reported: "i cannot get into the archived channel. there is no way for me to see it."
severity: major

## Summary

total: 12
passed: 11
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Navigate to an archived channel. You see the message history and a warning banner indicating the channel is archived. There is no message input form."
  status: failed
  reason: "User reported: i cannot get into the archived channel. there is no way for me to see it."
  severity: major
  test: 12
  root_cause: "Three compounding gaps: (1) list_for_user action filters status == :active so archived channels never appear in sidebar, (2) admin channel table links to settings drawer not chat view, (3) no other UI path exists to reach /channels/:id for archived channels — even though the chat view already handles archived state correctly with warning banner and hidden input"
  artifacts:
    - path: "lib/astraplex/messaging/channel.ex"
      issue: "list_for_user action filters out archived channels"
    - path: "lib/astraplex_web/live/admin/channel_list_live.ex"
      issue: "channel table links to /admin/channels/:id (settings), not /channels/:id (chat)"
  missing:
    - "Add 'View channel' link in admin channel table or settings drawer navigating to /channels/:id"
    - "Consider archived section in sidebar or searchable channel list for non-admin access"
  debug_session: ".planning/debug/archived-channel-inaccessible.md"
