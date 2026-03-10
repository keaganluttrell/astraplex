defmodule AstraplexWeb.DashboardLiveTest do
  @moduledoc false

  use AstraplexWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "admin dashboard" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :admin)
    end

    test "admin user sees admin shell with Astraplex branding", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Astraplex"
      assert html =~ "navbar"
    end

    test "admin user sees Admin link in sidebar", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "hero-shield-check"
      assert html =~ "/admin/users"
    end

    test "dashboard shows Home page header", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Home"
    end

    test "dashboard shows welcome empty state", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Welcome to Astraplex"
      assert html =~ "Your conversations will appear here"
    end

    test "user dropdown shows email and sign-out link", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ to_string(user.email)
      assert html =~ "Sign Out"
      assert html =~ "/sign-out"
    end
  end

  describe "staff dashboard" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :staff)
    end

    test "staff user sees staff shell without Admin link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Astraplex"
      refute html =~ "hero-shield-check"
      refute html =~ "/admin/users"
    end

    test "staff dashboard shows Home page header and welcome", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Home"
      assert html =~ "Welcome to Astraplex"
    end
  end
end
