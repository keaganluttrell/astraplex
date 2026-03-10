defmodule Astraplex.Accounts.UserAuthorizationTest do
  @moduledoc """
  Negative authorization tests per CVE-2025-48043.

  Proves that staff users and unauthenticated actors CANNOT perform
  admin-only actions. These tests are critical for ensuring policies
  are not bypassed.
  """

  use Astraplex.DataCase, async: true

  alias Astraplex.Accounts.User

  @valid_password "ValidPassword123!"

  defp seed_user(attrs) do
    {:ok, hashed} = AshAuthentication.BcryptProvider.hash(@valid_password)

    defaults = %{
      email: "user-#{System.unique_integer([:positive])}@example.com",
      hashed_password: hashed,
      role: :staff,
      status: :active
    }

    Ash.Seed.seed!(User, Map.merge(defaults, attrs))
  end

  describe "staff cannot perform admin actions (CVE-2025-48043)" do
    test "staff cannot create users" do
      staff = seed_user(%{role: :staff})

      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.create(
                 User,
                 %{
                   email: "new@test.com",
                   password: @valid_password,
                   password_confirmation: @valid_password,
                   role: :staff
                 },
                 action: :create_user,
                 actor: staff
               )
    end

    test "staff cannot deactivate users" do
      staff = seed_user(%{role: :staff})
      target = seed_user(%{role: :staff})

      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.update(target, %{}, action: :deactivate, actor: staff)
    end

    test "staff cannot reactivate users" do
      staff = seed_user(%{role: :staff})
      admin = seed_user(%{role: :admin})

      {:ok, deactivated} = Ash.update(staff, %{}, action: :deactivate, actor: admin)

      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.update(deactivated, %{}, action: :reactivate, actor: staff)
    end

    test "staff cannot update user roles" do
      staff = seed_user(%{role: :staff})
      target = seed_user(%{role: :staff})

      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.update(target, %{role: :admin}, action: :update_role, actor: staff)
    end
  end

  describe "unauthenticated access denied" do
    test "nil actor cannot create users" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.create(
                 User,
                 %{
                   email: "new@test.com",
                   password: @valid_password,
                   password_confirmation: @valid_password,
                   role: :staff
                 },
                 action: :create_user,
                 actor: nil
               )
    end

    test "nil actor cannot read user list" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.read(User, actor: nil)
    end
  end

  describe "deactivated admin cannot authenticate" do
    test "deactivated admin cannot sign in" do
      admin = seed_user(%{role: :admin})
      other_admin = seed_user(%{role: :admin})

      {:ok, _} = Ash.update(admin, %{}, action: :deactivate, actor: other_admin)

      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: admin.email,
                 password: @valid_password
               })
    end
  end
end
