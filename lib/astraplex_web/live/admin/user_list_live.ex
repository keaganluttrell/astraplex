defmodule AstraplexWeb.Admin.UserListLive do
  @moduledoc "Admin user management LiveView. Placeholder for Phase 4."

  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold">User Management</h1>
      <p>Coming soon.</p>
    </div>
    """
  end
end
