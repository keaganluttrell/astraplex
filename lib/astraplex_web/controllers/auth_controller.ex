defmodule AstraplexWeb.AuthController do
  @moduledoc "Handles authentication callbacks and sign-out."

  use AstraplexWeb, :controller
  use AshAuthentication.Phoenix.Controller

  @doc "Called on successful authentication. Stores user in session and redirects to root."
  @impl true
  def success(conn, _activity, user, _token) do
    conn
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> redirect(to: ~p"/")
  end

  @doc "Called on authentication failure. Redirects back to sign-in with generic error."
  @impl true
  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Invalid email or password")
    |> redirect(to: ~p"/sign-in")
  end

  @doc "Signs out the user by clearing the session and redirects to sign-in."
  @impl true
  def sign_out(conn, _params) do
    conn
    |> clear_session(:astraplex)
    |> redirect(to: ~p"/sign-in")
  end
end
