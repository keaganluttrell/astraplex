defmodule AstraplexWeb.LiveAuth do
  @moduledoc """
  on_mount hooks for protecting LiveView routes by authentication and role.

  ## Hooks

    * `:require_authenticated_user` - Requires an authenticated, active user.
      Redirects to /sign-in if not.
    * `:require_admin` - Requires an admin user. Redirects to / if not admin.
    * `:redirect_if_authenticated` - Redirects authenticated users away from
      the sign-in page.
  """

  import Phoenix.LiveView

  @doc """
  LiveView on_mount hook for authentication and authorization.

  See module documentation for available hook names.
  """
  def on_mount(:require_authenticated_user, _params, _session, socket) do
    case socket.assigns[:current_user] do
      %{status: :active} ->
        {:cont, socket}

      _ ->
        {:halt, redirect(socket, to: "/sign-in")}
    end
  end

  def on_mount(:require_admin, _params, _session, socket) do
    case socket.assigns[:current_user] do
      %{role: :admin, status: :active} ->
        {:cont, socket}

      _ ->
        {:halt, redirect(socket, to: "/")}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, _session, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:cont, socket}

      _ ->
        {:halt, redirect(socket, to: "/")}
    end
  end
end
