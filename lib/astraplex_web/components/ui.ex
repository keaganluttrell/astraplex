defmodule AstraplexWeb.Components.UI do
  @moduledoc "App-level reusable UI components for Astraplex."

  use Phoenix.Component

  import DaisyUIComponents.Icon, only: [icon: 1]

  @doc """
  Renders a page header with title and optional action buttons.

  ## Examples

      <.page_header title="Dashboard">
        <:actions>
          <button class="btn btn-primary btn-sm">New</button>
        </:actions>
      </.page_header>
  """
  attr :title, :string, required: true
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between px-6 py-4 border-b border-base-300">
      <h1 class="text-xl font-bold">{@title}</h1>
      <div :if={@actions != []} class="flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a centered empty state with optional icon, description, and action slot.

  ## Examples

      <.empty_state icon="hero-inbox" title="No messages" description="Start a conversation" />
  """
  attr :icon, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :actions

  def empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-12 text-center">
      <.icon :if={@icon} name={@icon} class="size-12 text-base-content/30 mb-4" />
      <h3 class="text-lg font-semibold text-base-content/70">{@title}</h3>
      <p :if={@description} class="mt-1 text-sm text-base-content/50 max-w-sm">{@description}</p>
      <div :if={@actions != []} class="mt-4">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a user avatar with initials derived from their email.

  Generates a deterministic background color based on the user's ID.
  Supports size variants and optional online/offline indicator.

  ## Examples

      <.user_avatar user={@current_user} />
      <.user_avatar user={@current_user} size="lg" show_indicator online />
  """
  attr :user, :map, required: true
  attr :size, :string, default: "md", values: ~w(xs sm md lg)
  attr :show_indicator, :boolean, default: false
  attr :online, :boolean, default: false

  def user_avatar(assigns) do
    ~H"""
    <div class={[
      "avatar placeholder",
      @show_indicator && ((@online && "avatar-online") || "avatar-offline")
    ]}>
      <div class={[
        "rounded-full text-white",
        avatar_bg_color(@user.id),
        avatar_size(@size)
      ]}>
        <span class={avatar_text_size(@size)}>
          {initials(@user.email)}
        </span>
      </div>
    </div>
    """
  end

  @doc """
  Renders a skeleton loading state for list views with 5 rows.

  Each row shows a circular placeholder and two line placeholders.
  """
  def skeleton_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-3 p-4">
      <div :for={_i <- 1..5} class="flex items-center gap-3">
        <div class="skeleton h-10 w-10 shrink-0 rounded-full"></div>
        <div class="flex flex-col gap-2 flex-1">
          <div class="skeleton h-4 w-1/3"></div>
          <div class="skeleton h-3 w-2/3"></div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a skeleton loading state for card views.

  Shows a rectangle placeholder and two line placeholders.
  """
  def skeleton_card(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 p-4">
      <div class="skeleton h-32 w-full rounded-lg"></div>
      <div class="skeleton h-4 w-3/4"></div>
      <div class="skeleton h-4 w-1/2"></div>
    </div>
    """
  end

  # Private helpers

  defp initials(email) do
    email
    |> to_string()
    |> String.split("@")
    |> hd()
    |> String.slice(0, 2)
    |> String.upcase()
  end

  defp avatar_bg_color(id) do
    colors = ~w(bg-primary bg-secondary bg-accent bg-info bg-success bg-warning bg-error)
    index = :erlang.phash2(id, length(colors))
    Enum.at(colors, index)
  end

  defp avatar_size("xs"), do: "w-6 h-6"
  defp avatar_size("sm"), do: "w-8 h-8"
  defp avatar_size("md"), do: "w-10 h-10"
  defp avatar_size("lg"), do: "w-14 h-14"

  defp avatar_text_size("xs"), do: "text-xs"
  defp avatar_text_size("sm"), do: "text-xs"
  defp avatar_text_size("md"), do: "text-sm"
  defp avatar_text_size("lg"), do: "text-lg"
end
