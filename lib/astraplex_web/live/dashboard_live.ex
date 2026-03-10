defmodule AstraplexWeb.DashboardLive do
  @moduledoc "Post-login landing page showing sidebar channels and welcome state."

  use AstraplexWeb, :live_view

  @doc false
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    channels = load_sidebar_channels(current_user)

    if connected?(socket) do
      AstraplexWeb.Endpoint.subscribe("membership:changed:#{current_user.id}")
    end

    {:ok, assign(socket, :channels, channels)}
  end

  def render(assigns) do
    ~H"""
    <%= if @current_user.role == :admin do %>
      <Layouts.admin_shell
        flash={@flash}
        current_user={@current_user}
        active_page={:home}
        channels={@channels}
        breadcrumb_path={[{"Home", nil}]}
      >
        <.empty_state
          icon="hero-chat-bubble-left-right"
          title="Welcome to Astraplex"
          description="Your conversations will appear here once channels are set up."
        />
      </Layouts.admin_shell>
    <% else %>
      <Layouts.staff_shell
        flash={@flash}
        current_user={@current_user}
        active_page={:home}
        channels={@channels}
        breadcrumb_path={[{"Home", nil}]}
      >
        <.empty_state
          icon="hero-chat-bubble-left-right"
          title="Welcome to Astraplex"
          description="Your conversations will appear here once channels are set up."
        />
      </Layouts.staff_shell>
    <% end %>
    """
  end

  @doc false
  def handle_info(%{topic: "membership:changed:" <> _}, socket) do
    channels = load_sidebar_channels(socket.assigns.current_user)
    {:noreply, assign(socket, :channels, channels)}
  end

  defp load_sidebar_channels(actor) do
    Astraplex.Messaging.Channel
    |> Ash.read!(action: :list_for_user, actor: actor)
    |> Enum.map(fn c ->
      %{id: to_string(c.id), label: "#" <> to_string(c.name), url: ~p"/channels/#{c.id}"}
    end)
  end
end
