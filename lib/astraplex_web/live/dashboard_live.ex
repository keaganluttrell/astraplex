defmodule AstraplexWeb.DashboardLive do
  @moduledoc "Post-login landing page. Placeholder for Phase 4+ channel views."

  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if @current_user.role == :admin do %>
      <Layouts.admin_shell flash={@flash} current_user={@current_user} active_page={:home}>
        <.page_header title="Home" />
        <.empty_state
          icon="hero-chat-bubble-left-right"
          title="Welcome to Astraplex"
          description="Your conversations will appear here once channels are set up."
        />
      </Layouts.admin_shell>
    <% else %>
      <Layouts.staff_shell flash={@flash} current_user={@current_user} active_page={:home}>
        <.page_header title="Home" />
        <.empty_state
          icon="hero-chat-bubble-left-right"
          title="Welcome to Astraplex"
          description="Your conversations will appear here once channels are set up."
        />
      </Layouts.staff_shell>
    <% end %>
    """
  end
end
