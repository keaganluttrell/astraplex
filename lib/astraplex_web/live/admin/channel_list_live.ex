defmodule AstraplexWeb.Admin.ChannelListLive do
  @moduledoc "Admin channel management LiveView for creating, editing, archiving channels and managing members."

  use AstraplexWeb, :live_view

  alias Astraplex.Accounts.User
  alias Astraplex.Messaging.Channel
  alias Astraplex.Messaging.Membership

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:channels, load_channels(socket))
     |> assign(:sidebar_channels, load_sidebar_channels(socket))
     |> assign(:users, load_users(socket))
     |> assign(:channel_form, nil)
     |> assign(:selected_channel, nil)
     |> assign(:member_search, "")
     |> assign(:selected_member_ids, [])
     |> assign(:show_user_picker, false)
     |> assign(:confirm_remove_member, nil)
     |> assign(:confirm_archive, false)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Channels")
    |> assign(:selected_channel, nil)
    |> assign(:channel_form, nil)
    |> assign(:show_user_picker, false)
    |> assign(:confirm_remove_member, nil)
    |> assign(:confirm_archive, false)
  end

  defp apply_action(socket, :new, _params) do
    form =
      Channel
      |> AshPhoenix.Form.for_create(:create, actor: socket.assigns.current_user, as: "channel")
      |> to_form()

    socket
    |> assign(:page_title, "New Channel")
    |> assign(:selected_channel, nil)
    |> assign(:channel_form, form)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    actor = socket.assigns.current_user
    channel = Ash.get!(Channel, id, actor: actor, load: [:members])

    form =
      channel
      |> AshPhoenix.Form.for_update(:update, actor: actor, as: "channel")
      |> to_form()

    socket
    |> assign(:page_title, "##{channel.name}")
    |> assign(:selected_channel, channel)
    |> assign(:channel_form, form)
    |> assign(:show_user_picker, false)
    |> assign(:selected_member_ids, [])
    |> assign(:member_search, "")
    |> assign(:confirm_remove_member, nil)
    |> assign(:confirm_archive, false)
  end

  # -- Events: Channel CRUD --

  def handle_event("validate_channel", %{"channel" => params}, socket) do
    form =
      socket.assigns.channel_form.source
      |> AshPhoenix.Form.validate(params, errors: false)
      |> to_form()

    {:noreply, assign(socket, :channel_form, form)}
  end

  def handle_event("save_channel", %{"channel" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.channel_form.source, params: params) do
      {:ok, _channel} ->
        redirect_path =
          if socket.assigns.selected_channel,
            do: ~p"/admin/channels/#{socket.assigns.selected_channel.id}",
            else: ~p"/admin/channels"

        {:noreply,
         socket
         |> put_flash(:info, "Channel saved successfully.")
         |> assign(:channels, load_channels(socket))
         |> assign(:sidebar_channels, load_sidebar_channels(socket))
         |> push_navigate(to: redirect_path)}

      {:error, form} ->
        {:noreply, assign(socket, :channel_form, to_form(form))}
    end
  end

  # -- Events: Archive --

  def handle_event("confirm_archive", _params, socket) do
    {:noreply, assign(socket, :confirm_archive, true)}
  end

  def handle_event("cancel_archive", _params, socket) do
    {:noreply, assign(socket, :confirm_archive, false)}
  end

  def handle_event("archive_channel", _params, socket) do
    Ash.update!(socket.assigns.selected_channel, %{},
      action: :archive,
      actor: socket.assigns.current_user
    )

    {:noreply,
     socket
     |> put_flash(:info, "Channel archived.")
     |> push_navigate(to: ~p"/admin/channels")}
  end

  # -- Events: Member management --

  def handle_event("toggle_user_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_user_picker, !socket.assigns.show_user_picker)
     |> assign(:selected_member_ids, [])
     |> assign(:member_search, "")}
  end

  def handle_event("search_members", %{"member_search" => search}, socket) do
    {:noreply, assign(socket, :member_search, search)}
  end

  def handle_event("toggle_member", %{"user-id" => user_id}, socket) do
    ids = socket.assigns.selected_member_ids

    updated =
      if user_id in ids,
        do: List.delete(ids, user_id),
        else: [user_id | ids]

    {:noreply, assign(socket, :selected_member_ids, updated)}
  end

  def handle_event("add_members", _params, socket) do
    actor = socket.assigns.current_user
    channel = socket.assigns.selected_channel

    Enum.each(socket.assigns.selected_member_ids, fn uid ->
      Ash.create!(Membership, %{channel_id: channel.id, user_id: uid}, actor: actor)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "Members added.")
     |> push_navigate(to: ~p"/admin/channels/#{channel.id}")}
  end

  def handle_event("confirm_remove_member", %{"user-id" => user_id}, socket) do
    member = Enum.find(socket.assigns.selected_channel.members, &(to_string(&1.id) == user_id))
    {:noreply, assign(socket, :confirm_remove_member, member)}
  end

  def handle_event("cancel_remove_member", _params, socket) do
    {:noreply, assign(socket, :confirm_remove_member, nil)}
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    actor = socket.assigns.current_user
    channel = socket.assigns.selected_channel

    membership =
      Membership
      |> Ash.read!(actor: actor)
      |> Enum.find(
        &(to_string(&1.channel_id) == to_string(channel.id) and to_string(&1.user_id) == user_id)
      )

    if membership, do: Ash.destroy!(membership, actor: actor)

    {:noreply,
     socket
     |> assign(:confirm_remove_member, nil)
     |> put_flash(:info, "Member removed.")
     |> push_navigate(to: ~p"/admin/channels/#{channel.id}")}
  end

  # -- Render --

  def render(assigns) do
    ~H"""
    <Layouts.admin_shell
      flash={@flash}
      current_user={@current_user}
      active_page={:admin}
      channels={@sidebar_channels}
      breadcrumb_path={[{"Admin", ~p"/admin/users"}, {"Channels", nil}]}
    >
      <div class="p-6">
        <div class="flex justify-end mb-4">
          <.link patch={~p"/admin/channels/new"} class="btn btn-primary btn-sm">New Channel</.link>
        </div>

        <.channel_table :if={@channels != []} channels={@channels} />
        <.empty_state
          :if={@channels == []}
          icon="hero-hashtag"
          title="No channels yet"
          description="Create your first channel to get started."
        />
      </div>
    </Layouts.admin_shell>

    <%!-- Fixed-position drawer panel — renders outside layout overflow --%>
    <div
      id="channel-drawer-overlay"
      style="z-index: 9999"
      class={[
        "fixed inset-0 bg-black/30 transition-opacity",
        if(@live_action in [:new, :show], do: "opacity-100", else: "opacity-0 pointer-events-none")
      ]}
      phx-click={JS.patch(~p"/admin/channels")}
    />
    <div
      id="channel-drawer"
      style="z-index: 10000"
      class={[
        "fixed top-0 right-0 h-full w-96 bg-base-100 shadow-xl border-l border-base-300 overflow-y-auto transition-transform duration-200",
        if(@live_action in [:new, :show], do: "translate-x-0", else: "translate-x-full")
      ]}
    >
      <.create_drawer_content :if={@live_action == :new && @channel_form} form={@channel_form} />
      <.settings_drawer_content
        :if={@live_action == :show && @selected_channel}
        channel={@selected_channel}
        form={@channel_form}
        users={available_users(@users, @selected_channel, @member_search)}
        show_user_picker={@show_user_picker}
        selected_member_ids={@selected_member_ids}
        member_search={@member_search}
        confirm_archive={@confirm_archive}
        confirm_remove_member={@confirm_remove_member}
      />
    </div>
    """
  end

  # -- Private components --

  defp channel_table(assigns) do
    ~H"""
    <.table id="channels" rows={@channels} row_id={fn ch -> "channel-#{ch.id}" end}>
      <:col :let={ch} label="Name">
        <span class="font-medium">#{ch.name}</span>
      </:col>
      <:col :let={ch} label="Description">
        <span class="truncate max-w-xs inline-block">{ch.description || "-"}</span>
      </:col>
      <:col :let={ch} label="Status">
        <.badge color={if ch.status == :active, do: "success", else: "warning"}>
          {status_label(ch.status)}
        </.badge>
      </:col>
      <:action :let={ch}>
        <.link navigate={~p"/channels/#{ch.id}"} class="btn btn-ghost btn-xs">
          <.icon name="hero-eye-micro" class="size-4" />
        </.link>
        <.link navigate={~p"/admin/channels/#{ch.id}"} class="btn btn-ghost btn-xs">
          <.icon name="hero-cog-6-tooth-micro" class="size-4" />
        </.link>
      </:action>
    </.table>
    """
  end

  defp create_drawer_content(assigns) do
    ~H"""
    <div class="p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-bold">Create Channel</h3>
        <.link patch={~p"/admin/channels"} class="btn btn-ghost btn-sm btn-circle">
          <.icon name="hero-x-mark-micro" class="size-5" />
        </.link>
      </div>
      <.form for={@form} phx-change="validate_channel" phx-submit="save_channel">
        <.form_input field={@form[:name]} label="Name" required />
        <.form_input field={@form[:description]} type="textarea" label="Description" />
        <div class="mt-4 flex justify-end gap-2">
          <.link patch={~p"/admin/channels"} class="btn btn-ghost">Cancel</.link>
          <.button type="submit" color="primary">Create Channel</.button>
        </div>
      </.form>
    </div>
    """
  end

  defp settings_drawer_content(assigns) do
    ~H"""
    <div class="p-6 flex flex-col gap-6">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-bold">Channel Settings</h3>
        <.link patch={~p"/admin/channels"} class="btn btn-ghost btn-sm btn-circle">
          <.icon name="hero-x-mark-micro" class="size-5" />
        </.link>
      </div>

      <%!-- Details section --%>
      <section>
        <h4 class="font-semibold text-sm mb-2">Details</h4>
        <.form for={@form} phx-change="validate_channel" phx-submit="save_channel">
          <.form_input field={@form[:name]} label="Name" required />
          <.form_input field={@form[:description]} type="textarea" label="Description" />
          <div class="mt-2 flex justify-end">
            <.button type="submit" color="primary" size="sm">Save Changes</.button>
          </div>
        </.form>
      </section>

      <div class="divider my-0"></div>

      <%!-- Members section --%>
      <section>
        <div class="flex items-center justify-between mb-2">
          <h4 class="font-semibold text-sm">Members ({length(@channel.members)})</h4>
          <button phx-click="toggle_user_picker" class="btn btn-ghost btn-xs">
            <.icon name="hero-user-plus-micro" class="size-4" /> Add
          </button>
        </div>

        <div :if={@show_user_picker} class="mb-4 p-3 bg-base-200 rounded-lg">
          <.user_picker
            users={@users}
            selected_ids={@selected_member_ids}
            search={@member_search}
            on_toggle="toggle_member"
            on_search="search_members"
          />
          <div class="mt-2 flex justify-end gap-2">
            <button phx-click="toggle_user_picker" class="btn btn-ghost btn-xs">Cancel</button>
            <button
              phx-click="add_members"
              class="btn btn-primary btn-xs"
              disabled={@selected_member_ids == []}
            >
              Add Selected
            </button>
          </div>
        </div>

        <.member_list
          members={@channel.members}
          removable
          on_remove="confirm_remove_member"
        />
      </section>

      <div class="divider my-0"></div>

      <%!-- Danger zone --%>
      <section>
        <h4 class="font-semibold text-sm text-error mb-2">Danger Zone</h4>
        <button phx-click="confirm_archive" class="btn btn-error btn-sm btn-outline w-full">
          Archive Channel
        </button>
      </section>

      <%!-- Archive confirmation --%>
      <div :if={@confirm_archive} class="p-4 bg-error/10 rounded-lg">
        <p class="mb-3">Archive <strong>#{@channel.name}</strong>? This will prevent new messages.</p>
        <div class="flex justify-end gap-2">
          <button phx-click="cancel_archive" class="btn btn-ghost btn-sm">Cancel</button>
          <button phx-click="archive_channel" class="btn btn-error btn-sm">Archive</button>
        </div>
      </div>

      <%!-- Remove member confirmation --%>
      <div :if={@confirm_remove_member} class="p-4 bg-error/10 rounded-lg">
        <p class="mb-3">
          Remove <strong>{@confirm_remove_member.email}</strong>
          from <strong>#{@channel.name}</strong>?
        </p>
        <div class="flex justify-end gap-2">
          <button phx-click="cancel_remove_member" class="btn btn-ghost btn-sm">Cancel</button>
          <button
            phx-click="remove_member"
            phx-value-user-id={@confirm_remove_member.id}
            class="btn btn-error btn-sm"
          >
            Remove
          </button>
        </div>
      </div>
    </div>
    """
  end

  # -- Helpers --

  defp available_users(users, channel, search) do
    member_ids = MapSet.new(channel.members, & &1.id)

    users
    |> Enum.reject(&MapSet.member?(member_ids, &1.id))
    |> Enum.filter(fn user ->
      search == "" or String.contains?(String.downcase(user.email), String.downcase(search))
    end)
  end

  defp load_sidebar_channels(socket) do
    Channel
    |> Ash.read!(action: :list_for_user, actor: socket.assigns.current_user)
    |> Enum.map(fn c ->
      %{
        id: to_string(c.id),
        label: "#" <> to_string(c.name),
        url: ~p"/channels/#{c.id}",
        archived: c.status == :archived
      }
    end)
  end

  defp load_channels(socket) do
    Channel
    |> Ash.read!(actor: socket.assigns.current_user)
    |> Enum.sort_by(& &1.name)
  end

  defp load_users(socket) do
    User
    |> Ash.read!(actor: socket.assigns.current_user)
    |> Enum.filter(&(&1.status == :active))
    |> Enum.sort_by(& &1.email)
  end

  defp status_label(:active), do: "Active"
  defp status_label(:archived), do: "Archived"
end
