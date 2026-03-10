defmodule AstraplexWeb.AuthLiveTest do
  @moduledoc false
  use AstraplexWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "unauthenticated access" do
    test "redirects / to /sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/")
    end
  end

  describe "sign-in page" do
    test "renders centered card with Astraplex title and form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/sign-in")

      assert html =~ "Astraplex"
      assert html =~ "Email"
      assert html =~ "Password"
      assert html =~ "Sign in"
    end

    test "shows error on invalid credentials submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/sign-in")

      html =
        lv
        |> form("form", user: %{email: "wrong@example.com", password: "bad"})
        |> render_submit()

      assert html =~ "Invalid email or password"
    end
  end

  describe "authenticated access" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn})
    end

    test "authenticated user can visit / and sees dashboard", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Welcome to Astraplex"
      assert html =~ to_string(user.email)
    end

    test "dashboard shows sign out link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Sign out"
      assert html =~ "/sign-out"
    end

    test "sign out via GET /sign-out redirects to /sign-in", %{conn: conn} do
      conn = get(conn, ~p"/sign-out")
      assert redirected_to(conn) =~ "/sign-in"
    end
  end

  describe "admin access" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :staff)
    end

    test "staff user visiting /admin/users is redirected to /", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/users")
    end
  end

  describe "admin can access admin routes" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :admin)
    end

    test "admin user can visit /admin/users", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "User Management"
    end
  end
end
