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
      "avatar avatar-placeholder",
      @show_indicator && ((@online && "avatar-online") || "avatar-offline")
    ]}>
      <div class={[
        "flex items-center justify-center rounded-full text-white",
        avatar_bg_color(@user.id),
        avatar_size(@size)
      ]}>
        <span class={["leading-none", avatar_text_size(@size)]}>
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

  @doc """
  Renders a breadcrumb navigation trail.

  Accepts a list of `{label, url}` tuples. The last item should have `nil` as the URL
  to indicate the current page (rendered as plain text, not a link).

  ## Examples

      <.breadcrumb path={[{"Astraplex", "/"}, {"Admin", "/admin/users"}, {"Users", nil}]} />
  """
  attr :path, :list, required: true

  def breadcrumb(assigns) do
    ~H"""
    <div class="breadcrumbs text-sm">
      <ul>
        <li :for={{label, url} <- @path}>
          <.link :if={url} navigate={url}>{label}</.link>
          <span :if={!url}>{label}</span>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders the Astraplex brand logo (planet icon) with optional size class.

  Uses `currentColor` so it inherits the text color from its parent.

  ## Examples

      <.brand_icon />
      <.brand_icon class="size-8" />
  """
  attr :class, :string, default: "size-6"

  def brand_icon(assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
      <path d="M12,3 C14.2247,3 16.2628,3.80843 17.8332,5.1461 C18.7641,4.92577 19.6183,4.82403 20.3399,4.88537 C21.0996,4.94995 21.9433,5.2226 22.3923,6.00018 C22.7985,6.70379 22.744,7.48932 22.4678,8.20408 C22.1964,8.90619 21.6812,9.63114 20.9869,10.3673 C20.9496,10.4068 20.9117,10.4465 20.8731,10.4864 C20.9566,10.9791 21,11.4848 21,12 C21,16.9706 16.9705,21 12,21 C9.81632,21 7.8123,20.2211 6.25397,18.9273 C6.19958,18.9409 6.14568,18.954 6.09227,18.9667 C5.10762,19.1999 4.22222,19.2836 3.47848,19.1675 C2.72097,19.0494 2.01274,18.7019 1.60766,18.0002 C1.15885,17.2229 1.34437,16.356 1.66808,15.666 C1.97561,15.0105 2.49063,14.3217 3.14663,13.6258 C3.05023,13.0978 2.99998,12.5544 2.99998,12 C2.99998,7.02944 7.02942,3 12,3 Z M3.3452,17.009 C3.20187,16.3005 4.3454,15.2581 4.75138,14.8419 C5.11329,14.471 5.25552,13.9483 5.15148,13.4564 C5.05233,12.9874 4.99998,12.5004 4.99998,12 C4.99998,8.13401 8.13399,5 12,5 C13.8012,5 15.4415,5.67902 16.6825,6.79667 C17.0568,7.13373 17.5812,7.27209 18.0838,7.14399 C18.6474,7.00034 20.1229,6.53073 20.6651,7.00935 C21.0006,7.71254 19.694,8.84095 19.2858,9.24773 C19.2825,9.25105 19.2792,9.25438 19.2759,9.25772 C18.0386,10.488 15.994,12.0037 13,13.7323 C10.0076,15.4599 7.67365,16.4726 5.98979,16.9293 C5.98489,16.9306 5.98,16.9319 5.97511,16.9332 C5.44801,17.0755 3.76639,17.6219 3.3452,17.009 Z M8.63264,18.1386 C10.1714,17.5248 11.9629,16.6404 14,15.4643 C16.0364,14.2886 17.6976,13.1796 18.9983,12.1542 C18.9163,15.949 15.8144,19 12,19 C10.7787,19 9.63157,18.6879 8.63264,18.1386 Z" />
    </svg>
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
