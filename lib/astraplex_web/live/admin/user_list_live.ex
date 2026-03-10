defmodule AstraplexWeb.Admin.UserListLive do
  @moduledoc "Admin user management LiveView for creating, viewing, and managing user accounts."

  use AstraplexWeb, :live_view

  alias Astraplex.Accounts.User

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, load_users(socket))}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :new) do
    form =
      User
      |> AshPhoenix.Form.for_create(:create_user, actor: socket.assigns.current_user, as: "user")
      |> to_form()

    assign(socket, form: form, page_title: "New User", confirm_deactivate_user: nil)
  end

  defp apply_action(socket, :index) do
    assign(socket, form: nil, page_title: "User Management", confirm_deactivate_user: nil)
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params, errors: false)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully.")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  def handle_event("change_role", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, &(to_string(&1.id) == id))
    new_role = if user.role == :staff, do: :admin, else: :staff

    Ash.update!(user, %{role: new_role},
      action: :update_role,
      actor: socket.assigns.current_user
    )

    {:noreply, assign(socket, :users, load_users(socket))}
  end

  def handle_event("confirm_deactivate", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :confirm_deactivate_user, user)}
  end

  def handle_event("cancel_deactivate", _params, socket) do
    {:noreply, assign(socket, :confirm_deactivate_user, nil)}
  end

  def handle_event("deactivate", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, &(to_string(&1.id) == id))

    Ash.update!(user, %{},
      action: :deactivate,
      actor: socket.assigns.current_user
    )

    {:noreply,
     socket
     |> assign(:confirm_deactivate_user, nil)
     |> assign(:users, load_users(socket))}
  end

  def handle_event("reactivate", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, &(to_string(&1.id) == id))

    Ash.update!(user, %{},
      action: :reactivate,
      actor: socket.assigns.current_user
    )

    {:noreply, assign(socket, :users, load_users(socket))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.admin_shell
      flash={@flash}
      current_user={@current_user}
      active_page={:admin}
      breadcrumb_path={[{"Astraplex", ~p"/"}, {"Admin", ~p"/admin/users"}, {"Users", nil}]}
    >
      <div class="p-6">
        <div class="flex justify-end mb-4">
          <.link navigate={~p"/admin/users/new"} class="btn btn-primary btn-sm">New User</.link>
        </div>
        <.table id="users" rows={@users} row_id={fn user -> "user-#{user.id}" end}>
          <:col :let={user} label="Email">{user.email}</:col>
          <:col :let={user} label="Role"><.role_badge role={user.role} /></:col>
          <:col :let={user} label="Status"><.status_badge status={user.status} /></:col>
          <:action :let={user}>
            <div class="flex gap-2">
              <button phx-click="change_role" phx-value-id={user.id} class="btn btn-ghost btn-xs">
                Change Role
              </button>
              <button
                :if={user.status == :active}
                phx-click="confirm_deactivate"
                phx-value-id={user.id}
                class="btn btn-ghost btn-xs text-error"
              >
                Deactivate
              </button>
              <button
                :if={user.status == :deactivated}
                phx-click="reactivate"
                phx-value-id={user.id}
                class="btn btn-ghost btn-xs text-success"
              >
                Reactivate
              </button>
            </div>
          </:action>
        </.table>
      </div>

      <.deactivate_modal :if={@confirm_deactivate_user} user={@confirm_deactivate_user} />

      <.modal
        :if={@live_action == :new}
        id="new-user-modal"
        show
        on_cancel={JS.navigate(~p"/admin/users")}
      >
        <h3 class="text-lg font-bold mb-4">Create New User</h3>
        <.form for={@form} phx-change="validate" phx-submit="save">
          <.form_input field={@form[:email]} type="email" label="Email" required />
          <.form_input field={@form[:password]} type="password" label="Password" required />
          <.form_input
            field={@form[:password_confirmation]}
            type="password"
            label="Password Confirmation"
            required
          />
          <.form_input
            field={@form[:role]}
            type="select"
            label="Role"
            options={[{"Staff", "staff"}, {"Admin", "admin"}]}
          />
          <div class="mt-4 flex justify-end gap-2">
            <.link navigate={~p"/admin/users"} class="btn btn-ghost">Cancel</.link>
            <.button type="submit" color="primary">Create User</.button>
          </div>
        </.form>
      </.modal>
    </Layouts.admin_shell>
    """
  end

  defp role_badge(assigns) do
    ~H"""
    <.badge color={if @role == :admin, do: "primary", else: "neutral"}>{role_label(@role)}</.badge>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <.badge color={if @status == :active, do: "success", else: "error"}>
      {status_label(@status)}
    </.badge>
    """
  end

  defp deactivate_modal(assigns) do
    ~H"""
    <.modal id="deactivate-modal" show on_cancel={JS.push("cancel_deactivate")}>
      <h3 class="text-lg font-bold mb-4">Confirm Deactivation</h3>
      <p>
        Are you sure you want to deactivate {@user.email}? They will be logged out immediately.
      </p>
      <div class="mt-4 flex justify-end gap-2">
        <button phx-click="cancel_deactivate" class="btn btn-ghost">Cancel</button>
        <button phx-click="deactivate" phx-value-id={@user.id} class="btn btn-error">
          Deactivate
        </button>
      </div>
    </.modal>
    """
  end

  defp load_users(socket) do
    User
    |> Ash.read!(actor: socket.assigns.current_user)
    |> Enum.sort_by(& &1.email)
  end

  defp role_label(:admin), do: "Admin"
  defp role_label(:staff), do: "Staff"

  defp status_label(:active), do: "Active"
  defp status_label(:deactivated), do: "Deactivated"
end
