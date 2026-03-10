defmodule AstraplexWeb.Components.Messaging do
  @moduledoc "Messaging-specific function components for channel views, member management, and chat."

  use Phoenix.Component

  import AstraplexWeb.Components.UI, only: [user_avatar: 1]
  import DaisyUIComponents.Icon, only: [icon: 1]

  @doc """
  Renders a list of channel members with avatars and optional remove button.

  ## Examples

      <.member_list members={@members} />
      <.member_list members={@members} removable on_remove="remove_member" />
  """
  attr :members, :list, required: true
  attr :removable, :boolean, default: false
  attr :on_remove, :string, default: nil

  def member_list(assigns) do
    ~H"""
    <ul class="flex flex-col gap-1">
      <li
        :for={member <- @members}
        class="flex items-center gap-3 py-2 px-2 rounded-lg hover:bg-base-200"
      >
        <.user_avatar user={member} size="sm" />
        <span class="flex-1 truncate text-sm">{member.email}</span>
        <button
          :if={@removable && @on_remove}
          phx-click={@on_remove}
          phx-value-user-id={member.id}
          class="btn btn-ghost btn-xs text-error"
          title="Remove member"
        >
          <.icon name="hero-x-mark-micro" class="size-4" />
        </button>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a searchable multi-select list of users to add to a channel.

  Users are pre-filtered to exclude existing members. Each row shows a checkbox,
  avatar, and email. Clicking a row toggles the user selection.

  ## Examples

      <.user_picker
        users={@available_users}
        selected_ids={@selected_member_ids}
        on_toggle="toggle_member"
        on_search="search_members"
      />
  """
  attr :users, :list, required: true
  attr :selected_ids, :list, default: []
  attr :search, :string, default: ""
  attr :on_toggle, :string, required: true
  attr :on_search, :string, required: true

  def user_picker(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <input
        type="text"
        placeholder="Search users..."
        value={@search}
        phx-change={@on_search}
        phx-debounce="300"
        name="member_search"
        class="input input-bordered input-sm w-full"
      />
      <ul class="flex flex-col gap-1 max-h-60 overflow-y-auto">
        <li
          :for={user <- @users}
          phx-click={@on_toggle}
          phx-value-user-id={user.id}
          class="flex items-center gap-3 py-2 px-2 rounded-lg hover:bg-base-200 cursor-pointer"
        >
          <input
            type="checkbox"
            checked={user.id in @selected_ids}
            class="checkbox checkbox-sm checkbox-primary"
            tabindex="-1"
          />
          <.user_avatar user={user} size="sm" />
          <span class="text-sm truncate">{user.email}</span>
        </li>
        <li :if={@users == []} class="py-4 text-center text-sm text-base-content/50">
          No users found
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a single chat message with sender avatar and timestamp.

  Own messages are aligned right with a primary background. Other messages
  are aligned left with the default background.

  ## Examples

      <.message_bubble message={msg} current_user_id={@current_user.id} />
  """
  attr :message, :map, required: true
  attr :current_user_id, :string, required: true

  def message_bubble(assigns) do
    assigns =
      assign(
        assigns,
        :own?,
        to_string(assigns.message.sender.id) == to_string(assigns.current_user_id)
      )

    ~H"""
    <div class={["chat", if(@own?, do: "chat-end", else: "chat-start")]}>
      <div class="chat-image">
        <.user_avatar user={@message.sender} size="sm" />
      </div>
      <div class="chat-header text-xs text-base-content/60 mb-1">
        {@message.sender.email}
        <time class="text-xs text-base-content/40 ml-1">{format_time(@message.inserted_at)}</time>
      </div>
      <div class={["chat-bubble", if(@own?, do: "chat-bubble-primary", else: "")]}>
        {@message.body}
      </div>
    </div>
    """
  end

  defp format_time(%DateTime{} = dt) do
    Calendar.strftime(dt, "%H:%M")
  end

  defp format_time(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%H:%M")
  end

  defp format_time(_), do: ""
end
