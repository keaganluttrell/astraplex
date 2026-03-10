defmodule Astraplex.Factory do
  @moduledoc """
  Smokestack factory definitions for test data.

  Factories use Ash.Seed.seed! for prerequisite data setup.
  For testing specific behavior, invoke Ash actions directly.
  """
  use Smokestack

  factory Astraplex.Accounts.User do
    attribute(:email, fn -> "user-#{System.unique_integer([:positive])}@example.com" end)
    attribute(:role, fn -> :staff end)
    attribute(:status, fn -> :active end)

    attribute(:hashed_password, fn ->
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")
      hashed
    end)
  end
end
