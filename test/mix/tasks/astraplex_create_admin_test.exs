defmodule Mix.Tasks.Astraplex.CreateAdminTest do
  @moduledoc false

  use Astraplex.DataCase, async: false

  alias Astraplex.Accounts.User
  alias Mix.Tasks.Astraplex.CreateAdmin

  describe "mix astraplex.create_admin" do
    test "creates an admin user with valid email and password" do
      CreateAdmin.run(["admin@test.com", "SecurePass123!"])

      assert [user] = Ash.read!(User, authorize?: false)
      assert to_string(user.email) == "admin@test.com"
      assert user.role == :admin
      assert user.status == :active
    end

    test "prints usage and exits with error when no args given" do
      assert_raise Mix.Error, ~r/Usage/, fn ->
        CreateAdmin.run([])
      end
    end

    test "fails gracefully with duplicate email" do
      CreateAdmin.run(["dupe@test.com", "SecurePass123!"])

      assert_raise Mix.Error, ~r/already|exists|unique|taken/i, fn ->
        CreateAdmin.run(["dupe@test.com", "AnotherPass123!"])
      end
    end
  end
end
