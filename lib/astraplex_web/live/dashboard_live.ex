defmodule AstraplexWeb.DashboardLive do
  @moduledoc "Post-login landing page. Placeholder for Phase 4+ channel views."

  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold">Welcome to Astraplex</h1>
      <p class="mt-2">Logged in as {@current_user.email}</p>
      <.link href={~p"/sign-out"} method="get" class="btn btn-ghost mt-4">
        Sign out
      </.link>
    </div>
    """
  end
end
