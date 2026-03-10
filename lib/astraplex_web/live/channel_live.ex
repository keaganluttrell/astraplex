defmodule AstraplexWeb.ChannelLive do
  @moduledoc "Channel chat view with real-time message delivery via PubSub."

  use AstraplexWeb, :live_view

  @doc false
  def mount(%{"id" => channel_id}, _session, socket) do
    current_user = socket.assigns.current_user

    channel = Ash.get!(Astraplex.Messaging.Channel, channel_id, actor: current_user)

    messages = load_messages(channel_id, current_user)
    channels = load_sidebar_channels(current_user)

    if connected?(socket) do
      AstraplexWeb.Endpoint.subscribe("channel:messages:#{channel_id}")
      AstraplexWeb.Endpoint.subscribe("membership:changed:#{current_user.id}")
    end

    socket =
      socket
      |> assign(:channel, channel)
      |> assign(:channels, channels)
      |> assign(:current_channel_id, to_string(channel.id))
      |> assign(:has_messages?, messages != [])
      |> stream(:messages, messages)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if @current_user.role == :admin do %>
      <Layouts.admin_shell
        flash={@flash}
        current_user={@current_user}
        active_page={nil}
        channels={@channels}
        current_channel_id={@current_channel_id}
        breadcrumb_path={[{"Home", "/"}, {"#" <> to_string(@channel.name), nil}]}
      >
        <.channel_content
          channel={@channel}
          current_user={@current_user}
          streams={@streams}
          has_messages?={@has_messages?}
        />
      </Layouts.admin_shell>
    <% else %>
      <Layouts.staff_shell
        flash={@flash}
        current_user={@current_user}
        active_page={nil}
        channels={@channels}
        current_channel_id={@current_channel_id}
        breadcrumb_path={[{"Home", "/"}, {"#" <> to_string(@channel.name), nil}]}
      >
        <.channel_content
          channel={@channel}
          current_user={@current_user}
          streams={@streams}
          has_messages?={@has_messages?}
        />
      </Layouts.staff_shell>
    <% end %>
    """
  end

  attr :channel, :map, required: true
  attr :current_user, :map, required: true
  attr :streams, :map, required: true
  attr :has_messages?, :boolean, required: true

  defp channel_content(assigns) do
    ~H"""
    <Layouts.chat_layout title={"#" <> to_string(@channel.name)}>
      <:title_action>
        <.link
          :if={@current_user.role == :admin}
          navigate={~p"/admin/channels/#{@channel.id}"}
          class="btn btn-ghost btn-sm"
        >
          <.icon name="hero-cog-6-tooth" class="size-4" />
        </.link>
      </:title_action>

      <.empty_state
        :if={!@has_messages?}
        icon="hero-chat-bubble-left-right"
        title="No messages yet"
        description="Be the first to say something!"
      />

      <div id="messages" phx-update="stream" class="flex flex-col gap-1">
        <div :for={{dom_id, message} <- @streams.messages} id={dom_id}>
          <.message_bubble message={message} current_user_id={to_string(@current_user.id)} />
        </div>
      </div>

      <:input>
        <%= if @channel.status == :archived do %>
          <div class="alert alert-warning">
            <.icon name="hero-archive-box" class="size-5" />
            <span>This channel has been archived.</span>
          </div>
        <% else %>
          <form phx-submit="send_message" class="flex gap-2">
            <input
              type="text"
              name="body"
              placeholder={"Message #" <> to_string(@channel.name)}
              class="input input-bordered flex-1"
              autocomplete="off"
              required
            />
            <button type="submit" class="btn btn-primary">
              <.icon name="hero-paper-airplane" class="size-5" />
            </button>
          </form>
        <% end %>
      </:input>
    </Layouts.chat_layout>
    """
  end

  @doc false
  def handle_event("new_channel_sidebar", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"body" => body}, socket) do
    %{channel: channel, current_user: current_user} = socket.assigns

    Ash.create!(
      Astraplex.Messaging.Message,
      %{body: body, channel_id: channel.id},
      action: :send_message,
      actor: current_user
    )

    {:noreply, socket}
  end

  @doc false
  def handle_info(%{topic: "channel:messages:" <> _} = notification, socket) do
    message =
      notification.payload.data
      |> Ash.load!([:sender], actor: socket.assigns.current_user)

    socket =
      socket
      |> assign(:has_messages?, true)
      |> stream_insert(:messages, message, at: -1)

    {:noreply, socket}
  end

  def handle_info(%{topic: "membership:changed:" <> _}, socket) do
    channels = load_sidebar_channels(socket.assigns.current_user)
    {:noreply, assign(socket, :channels, channels)}
  end

  defp load_messages(channel_id, actor) do
    require Ash.Query

    Astraplex.Messaging.Message
    |> Ash.Query.filter(channel_id == ^channel_id)
    |> Ash.Query.sort(inserted_at: :asc)
    |> Ash.Query.limit(50)
    |> Ash.Query.load([:sender])
    |> Ash.read!(actor: actor)
  end

  defp load_sidebar_channels(actor) do
    Astraplex.Messaging.Channel
    |> Ash.read!(action: :list_for_user, actor: actor)
    |> Enum.map(fn c ->
      %{id: to_string(c.id), label: "#" <> to_string(c.name), url: ~p"/channels/#{c.id}"}
    end)
  end
end
