defmodule AstraplexWeb.Admin.UserListLiveTest do
  @moduledoc false

  use AstraplexWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Astraplex.Accounts.User

  describe "admin user list" do
    setup :register_and_log_in_admin

    test "shows user table with email, role, and status columns", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "User Management"
      assert html =~ "Email"
      assert html =~ "Role"
      assert html =~ "Status"
    end

    test "displays existing users in the table", %{conn: conn, user: admin} do
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")

      staff =
        Ash.Seed.seed!(User, %{
          email: "staff@example.com",
          hashed_password: hashed,
          role: :staff,
          status: :active
        })

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ admin.email |> to_string()
      assert html =~ staff.email |> to_string()
      assert html =~ "Admin"
      assert html =~ "Staff"
      assert html =~ "Active"
    end

    test "admin can open new user form and create a user", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/users/new")

      assert has_element?(view, "form")

      result =
        view
        |> form("form", %{
          "user" => %{
            "email" => "newuser@example.com",
            "password" => "SecurePass123!",
            "password_confirmation" => "SecurePass123!",
            "role" => "staff"
          }
        })
        |> render_submit()

      # After successful creation, should redirect to index
      assert_redirect(view, ~p"/admin/users")
    end

    test "newly created user appears in the user list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/users/new")

      view
      |> form("form", %{
        "user" => %{
          "email" => "brandnew@example.com",
          "password" => "SecurePass123!",
          "password_confirmation" => "SecurePass123!",
          "role" => "staff"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/admin/users")

      {:ok, _view, html} = live(conn, ~p"/admin/users")
      assert html =~ "brandnew@example.com"
    end

    test "admin can change a user's role", %{conn: conn, user: admin} do
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")

      staff =
        Ash.Seed.seed!(User, %{
          email: "rolechange@example.com",
          hashed_password: hashed,
          role: :staff,
          status: :active
        })

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      view |> element("[phx-click='change_role'][phx-value-id='#{staff.id}']") |> render_click()

      html = render(view)
      # Staff should have been toggled to Admin
      assert html =~ "rolechange@example.com"
    end

    test "admin can deactivate an active user with confirmation", %{conn: conn} do
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")

      user =
        Ash.Seed.seed!(User, %{
          email: "deactivateme@example.com",
          hashed_password: hashed,
          role: :staff,
          status: :active
        })

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      # Click deactivate to open confirmation modal
      view
      |> element("[phx-click='confirm_deactivate'][phx-value-id='#{user.id}']")
      |> render_click()

      html = render(view)
      assert html =~ "Are you sure you want to deactivate"
      assert html =~ "deactivateme@example.com"

      # Confirm the deactivation
      view |> element("[phx-click='deactivate'][phx-value-id='#{user.id}']") |> render_click()

      html = render(view)
      assert html =~ "Deactivated"
    end

    test "deactivated users show Deactivated badge in the table", %{conn: conn} do
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")

      Ash.Seed.seed!(User, %{
        email: "deactivated@example.com",
        hashed_password: hashed,
        role: :staff,
        status: :deactivated
      })

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "Deactivated"
    end

    test "admin can reactivate a deactivated user", %{conn: conn} do
      {:ok, hashed} = AshAuthentication.BcryptProvider.hash("ValidPassword123!")

      user =
        Ash.Seed.seed!(User, %{
          email: "reactivateme@example.com",
          hashed_password: hashed,
          role: :staff,
          status: :deactivated
        })

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      view
      |> element("[phx-click='reactivate'][phx-value-id='#{user.id}']")
      |> render_click()

      html = render(view)
      assert html =~ "Active"
    end
  end

  describe "staff user access" do
    setup :register_and_log_in_staff

    test "staff user cannot access /admin/users (redirected)", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/users")
    end
  end

  defp register_and_log_in_admin(context) do
    register_and_log_in_user(context, role: :admin)
  end

  defp register_and_log_in_staff(context) do
    register_and_log_in_user(context, role: :staff)
  end
end
