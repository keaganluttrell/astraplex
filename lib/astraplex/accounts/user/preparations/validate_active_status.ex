defmodule Astraplex.Accounts.User.Preparations.ValidateActiveStatus do
  @moduledoc "Filters sign-in results to only active users, blocking deactivated accounts."

  use Ash.Resource.Preparation

  @doc false
  @impl true
  def prepare(query, _opts, _context) do
    Ash.Query.filter(query, status == :active)
  end
end
