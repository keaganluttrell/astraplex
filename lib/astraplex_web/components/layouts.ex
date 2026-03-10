defmodule AstraplexWeb.Layouts do
  @moduledoc """
  Layout function components for Astraplex.

  Provides role-based shell layouts (admin_shell, staff_shell) that compose
  a shared base shell with top bar, sidebar, flash messages, and user dropdown.

  ## Usage in LiveViews

      def render(assigns) do
        ~H\"\"\"
        <Layouts.admin_shell flash={@flash} current_user={@current_user} active_page={:admin}
          breadcrumb_path={[{"Astraplex", "/"}, {"Admin", "/admin/users"}, {"Users", nil}]}>
          <%-- page content --%>
        </Layouts.admin_shell>
        \"\"\"
      end
  """
  use AstraplexWeb, :html

  embed_templates "layouts/*"

  # -- Public shell layouts --

  @doc """
  Renders the admin shell layout with sidebar showing the Admin link.

  Accepts `active_page` to highlight the corresponding sidebar nav item.
  """
  attr :flash, :map, required: true
  attr :current_user, :map, required: true
  attr :active_page, :atom, default: nil
  attr :breadcrumb_path, :list, default: []
  slot :inner_block, required: true

  def admin_shell(assigns) do
    ~H"""
    <.base_shell flash={@flash} current_user={@current_user} breadcrumb_path={@breadcrumb_path}>
      <.app_sidebar
        current_user={@current_user}
        role={:admin}
        active_page={@active_page}
        class="hidden md:flex"
      />
      <main class="flex-1 overflow-y-auto pb-16 md:pb-0">
        {render_slot(@inner_block)}
      </main>
      <.mobile_dock current_user={@current_user} role={:admin} active_page={@active_page} />
      <.apps_bottom_sheet role={:admin} />
    </.base_shell>
    """
  end

  @doc """
  Renders the staff shell layout with sidebar hiding the Admin link.

  Accepts `active_page` to highlight the corresponding sidebar nav item.
  """
  attr :flash, :map, required: true
  attr :current_user, :map, required: true
  attr :active_page, :atom, default: nil
  attr :breadcrumb_path, :list, default: []
  slot :inner_block, required: true

  def staff_shell(assigns) do
    ~H"""
    <.base_shell flash={@flash} current_user={@current_user} breadcrumb_path={@breadcrumb_path}>
      <.app_sidebar
        current_user={@current_user}
        role={:staff}
        active_page={@active_page}
        class="hidden md:flex"
      />
      <main class="flex-1 overflow-y-auto pb-16 md:pb-0">
        {render_slot(@inner_block)}
      </main>
      <.mobile_dock current_user={@current_user} role={:staff} active_page={@active_page} />
      <.apps_bottom_sheet role={:staff} />
    </.base_shell>
    """
  end

  @doc """
  Renders a chat view layout with header, scrollable message area, and pinned input bar.

  Establishes the standard messaging layout pattern used by channel and conversation views.

  ## Examples

      <Layouts.chat_layout title="#general">
        <div :for={msg <- @messages}>...</div>
        <:input>
          <form phx-submit="send"><input name="body" /></form>
        </:input>
      </Layouts.chat_layout>
  """
  attr :title, :string, required: true
  attr :class, :string, default: ""
  slot :input
  slot :inner_block, required: true

  def chat_layout(assigns) do
    ~H"""
    <div class={["flex flex-col h-full", @class]}>
      <div class="flex items-center px-4 py-3 border-b border-base-300 shrink-0">
        <h2 class="font-semibold">{@title}</h2>
      </div>
      <div class="flex-1 overflow-y-auto px-4 py-2">
        {render_slot(@inner_block)}
      </div>
      <div :if={@input != []} class="border-t border-base-300 px-4 py-3 shrink-0">
        {render_slot(@input)}
      </div>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  # -- Private components --

  attr :flash, :map, required: true
  attr :current_user, :map, required: true
  attr :breadcrumb_path, :list, default: []
  slot :inner_block, required: true

  defp base_shell(assigns) do
    ~H"""
    <.top_bar breadcrumb_path={@breadcrumb_path} />
    <div class="flex h-[calc(100vh-4rem)]">
      {render_slot(@inner_block)}
    </div>
    <.flash_group flash={@flash} />
    """
  end

  attr :breadcrumb_path, :list, default: []

  defp top_bar(assigns) do
    ~H"""
    <.navbar class="bg-base-100 border-b border-base-300 px-4 h-16 shrink-0">
      <:navbar_start>
        <.breadcrumb :if={@breadcrumb_path != []} path={@breadcrumb_path} />
        <.link
          :if={@breadcrumb_path == []}
          navigate={~p"/"}
          class="flex items-center gap-2 text-xl font-bold"
        >
          <.brand_icon class="size-6 text-primary" /> Astraplex
        </.link>
      </:navbar_start>
      <:navbar_end>
        <input
          type="text"
          placeholder="Search..."
          class="input input-bordered input-sm w-48 hidden md:block"
          disabled
        />
      </:navbar_end>
    </.navbar>
    """
  end

  attr :current_user, :map, required: true
  attr :role, :atom, required: true, values: [:admin, :staff]
  attr :active_page, :atom, default: nil
  attr :class, :string, default: ""

  defp app_sidebar(assigns) do
    ~H"""
    <aside class={[
      "w-64 bg-base-200 border-r border-base-300 flex flex-col overflow-y-auto overflow-x-hidden",
      @class
    ]}>
      <%!-- Navigation links --%>
      <ul class="menu">
        <li>
          <.link navigate={~p"/"} class={@active_page == :home && "menu-active"}>
            <.icon name="hero-home" class="size-5" /> Home
          </.link>
        </li>
        <li :if={@role == :admin}>
          <.link navigate={~p"/admin/users"} class={@active_page == :admin && "menu-active"}>
            <.icon name="hero-shield-check" class="size-5" /> Admin
          </.link>
        </li>
      </ul>

      <div class="divider my-1 px-3"></div>

      <%!-- Collapsible messaging sections --%>
      <.sidebar_group title="Channels" placeholder="(No channels yet)" />
      <.sidebar_group title="Direct Messages" placeholder="(No conversations yet)" />
      <.sidebar_group title="Groups" placeholder="(No groups yet)" />

      <%!-- User info area --%>
      <div class="mt-auto border-t border-base-300 p-3">
        <.dropdown direction="top" align="end" class="w-full">
          <div
            tabindex="0"
            role="button"
            class="flex items-center gap-2 rounded-lg p-2 hover:bg-base-300 cursor-pointer w-full"
          >
            <.user_avatar user={@current_user} size="sm" />
            <span class="flex-1 truncate text-sm">{@current_user.email}</span>
            <.icon name="hero-chevron-up-micro" class="size-4 opacity-50" />
          </div>
          <div
            tabindex="0"
            class="dropdown-content bg-base-100 rounded-box z-[1] w-60 p-3 shadow-lg mb-2"
          >
            <div class="mb-3">
              <.theme_toggle />
            </div>
            <ul class="menu menu-sm p-0">
              <li>
                <.link href={~p"/sign-out"} class="text-error">
                  <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Sign Out
                </.link>
              </li>
            </ul>
          </div>
        </.dropdown>
      </div>
    </aside>
    """
  end

  attr :title, :string, required: true
  attr :placeholder, :string, required: true

  defp sidebar_group(assigns) do
    ~H"""
    <details open class="group px-2">
      <summary class="flex items-center justify-between px-3 py-2 cursor-pointer text-sm font-semibold text-base-content/70 hover:text-base-content list-none">
        {@title}
        <.icon
          name="hero-chevron-down-micro"
          class="size-4 transition-transform group-open:rotate-180"
        />
      </summary>
      <ul class="menu menu-sm pl-2">
        <li class="disabled">
          <span class="text-base-content/40 text-xs">{@placeholder}</span>
        </li>
      </ul>
    </details>
    """
  end

  attr :current_user, :map, required: true
  attr :role, :atom, required: true, values: [:admin, :staff]
  attr :active_page, :atom, default: nil
  attr :class, :string, default: ""

  defp mobile_dock(assigns) do
    ~H"""
    <div class={["dock md:hidden", @class]}>
      <.link navigate={~p"/"} class={@active_page == :home && "dock-active"}>
        <.icon name="hero-home" class="size-5" />
        <span class="dock-label">Home</span>
      </.link>

      <button class={@active_page == :inbox && "dock-active"}>
        <span class="indicator">
          <span class="indicator-item badge badge-sm badge-primary hidden"></span>
          <.icon name="hero-inbox" class="size-5" />
        </span>
        <span class="dock-label">Inbox</span>
      </button>

      <button phx-click={show_modal("apps-sheet")}>
        <.icon name="hero-squares-2x2" class="size-5" />
        <span class="dock-label">Apps</span>
      </button>

      <button>
        <.icon name="hero-plus-circle" class="size-5" />
        <span class="dock-label">Create</span>
      </button>
    </div>
    """
  end

  attr :role, :atom, required: true, values: [:admin, :staff]

  defp apps_bottom_sheet(assigns) do
    ~H"""
    <.modal id="apps-sheet" class="modal-bottom" close_on_click_away>
      <h3 class="text-lg font-bold mb-4">Apps</h3>
      <ul class="menu menu-lg w-full">
        <li :if={@role == :admin}>
          <.link navigate={~p"/admin/users"} phx-click={hide_modal("apps-sheet")}>
            <.icon name="hero-shield-check" class="size-5" /> Admin
          </.link>
        </li>
        <li>
          <.link navigate={~p"/"} phx-click={hide_modal("apps-sheet")}>
            <.icon name="hero-home" class="size-5" /> Home
          </.link>
        </li>
      </ul>
    </.modal>
    """
  end
end
