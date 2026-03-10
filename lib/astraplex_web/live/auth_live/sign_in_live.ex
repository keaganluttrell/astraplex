defmodule AstraplexWeb.AuthLive.SignInLive do
  @moduledoc "Custom sign-in LiveView with centered card layout."

  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <p>Sign in placeholder</p>
    </div>
    """
  end
end
