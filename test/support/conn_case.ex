defmodule AstraplexWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AstraplexWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias AshAuthentication.Plug.Helpers, as: AuthHelpers
  alias Astraplex.Accounts.User

  using do
    quote do
      # The default endpoint for testing
      @endpoint AstraplexWeb.Endpoint

      use AstraplexWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import AstraplexWeb.ConnCase
      import Astraplex.Factory
    end
  end

  setup tags do
    Astraplex.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc "Creates a user and logs them in on the connection."
  @spec register_and_log_in_user(map(), keyword()) :: map()
  def register_and_log_in_user(%{conn: conn} = context, opts \\ []) do
    role = Keyword.get(opts, :role, :staff)
    email = Keyword.get(opts, :email, "user-#{System.unique_integer([:positive])}@example.com")
    password = "ValidPassword123!"

    {:ok, hashed} = AshAuthentication.BcryptProvider.hash(password)

    user =
      Ash.Seed.seed!(User, %{
        email: email,
        hashed_password: hashed,
        role: role,
        status: :active
      })

    strategy = AshAuthentication.Info.strategy!(User, :password)

    {:ok, signed_in_user} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{
        email: email,
        password: password
      })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> AuthHelpers.store_in_session(signed_in_user)

    Map.merge(context, %{conn: conn, user: user})
  end
end
