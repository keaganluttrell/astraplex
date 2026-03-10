defmodule Astraplex.Accounts.UserTest do
  @moduledoc "Integration tests for User resource actions."

  use Astraplex.DataCase, async: true

  alias Astraplex.Accounts.User

  @valid_password "ValidPassword123!"

  defp create_admin do
    {:ok, hashed} = AshAuthentication.BcryptProvider.hash(@valid_password)

    Ash.Seed.seed!(User, %{
      email: "admin-#{System.unique_integer([:positive])}@example.com",
      hashed_password: hashed,
      role: :admin,
      status: :active
    })
  end

  defp create_staff do
    {:ok, hashed} = AshAuthentication.BcryptProvider.hash(@valid_password)

    Ash.Seed.seed!(User, %{
      email: "staff-#{System.unique_integer([:positive])}@example.com",
      hashed_password: hashed,
      role: :staff,
      status: :active
    })
  end

  describe "create_user" do
    test "admin can create a user with email, password, and role :staff" do
      admin = create_admin()

      assert {:ok, user} =
               Ash.create(
                 User,
                 %{
                   email: "newstaff@example.com",
                   password: @valid_password,
                   password_confirmation: @valid_password,
                   role: :staff
                 },
                 action: :create_user,
                 actor: admin
               )

      assert to_string(user.email) == "newstaff@example.com"
      assert user.role == :staff
    end

    test "admin can create a user with role :admin" do
      admin = create_admin()

      assert {:ok, user} =
               Ash.create(
                 User,
                 %{
                   email: "newadmin@example.com",
                   password: @valid_password,
                   password_confirmation: @valid_password,
                   role: :admin
                 },
                 action: :create_user,
                 actor: admin
               )

      assert user.role == :admin
    end

    test "created user has status :active by default" do
      admin = create_admin()

      assert {:ok, user} =
               Ash.create(
                 User,
                 %{
                   email: "default-status@example.com",
                   password: @valid_password,
                   password_confirmation: @valid_password
                 },
                 action: :create_user,
                 actor: admin
               )

      assert user.status == :active
    end

    test "email uniqueness constraint rejects duplicate emails" do
      admin = create_admin()

      assert {:ok, _} =
               Ash.create(
                 User,
                 %{
                   email: "duplicate@example.com",
                   password: @valid_password,
                   password_confirmation: @valid_password
                 },
                 action: :create_user,
                 actor: admin
               )

      assert {:error, _} =
               Ash.create(
                 User,
                 %{
                   email: "duplicate@example.com",
                   password: @valid_password,
                   password_confirmation: @valid_password
                 },
                 action: :create_user,
                 actor: admin
               )
    end
  end

  describe "update_role" do
    test "admin can update a user's role from :staff to :admin" do
      admin = create_admin()
      staff = create_staff()

      assert {:ok, updated} =
               Ash.update(staff, %{role: :admin}, action: :update_role, actor: admin)

      assert updated.role == :admin
    end

    test "admin can update a user's role from :admin to :staff" do
      admin = create_admin()
      other_admin = create_admin()

      assert {:ok, updated} =
               Ash.update(other_admin, %{role: :staff}, action: :update_role, actor: admin)

      assert updated.role == :staff
    end
  end

  describe "deactivate and reactivate" do
    test "admin can deactivate an active user" do
      admin = create_admin()
      staff = create_staff()

      assert {:ok, deactivated} =
               Ash.update(staff, %{}, action: :deactivate, actor: admin)

      assert deactivated.status == :deactivated
    end

    test "admin can reactivate a deactivated user" do
      admin = create_admin()
      staff = create_staff()

      {:ok, deactivated} = Ash.update(staff, %{}, action: :deactivate, actor: admin)
      assert deactivated.status == :deactivated

      assert {:ok, reactivated} =
               Ash.update(deactivated, %{}, action: :reactivate, actor: admin)

      assert reactivated.status == :active
    end
  end

  describe "sign_in_with_password" do
    test "succeeds with valid email and password for active user" do
      admin = create_admin()

      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:ok, signed_in} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: admin.email,
                 password: @valid_password
               })

      assert signed_in.id == admin.id
    end

    test "fails for deactivated user even with correct credentials" do
      admin = create_admin()
      staff = create_staff()

      {:ok, _deactivated} = Ash.update(staff, %{}, action: :deactivate, actor: admin)

      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: staff.email,
                 password: @valid_password
               })
    end

    test "fails with wrong password" do
      _admin = create_admin()
      staff = create_staff()

      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: staff.email,
                 password: "WrongPassword123!"
               })
    end

    test "fails with nonexistent email" do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: "nonexistent@example.com",
                 password: @valid_password
               })
    end
  end
end
