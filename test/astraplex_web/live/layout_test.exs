defmodule AstraplexWeb.LayoutTest do
  @moduledoc false
  use AstraplexWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "admin shell layout" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :admin)
    end

    test "shows top bar with Astraplex branding", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Astraplex"
      assert html =~ "navbar"
    end

    test "admin user sees Admin link in sidebar", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Admin"
      assert html =~ "hero-shield-check"
      assert html =~ "/admin/users"
    end

    test "sidebar shows Channels, Direct Messages, Groups sections", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Channels"
      assert html =~ "Direct Messages"
      assert html =~ "Groups"
    end

    test "user dropdown contains Sign Out link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Sign Out"
      assert html =~ "/sign-out"
    end

    test "search input placeholder is present", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ ~s(placeholder="Search...")
      assert html =~ "disabled"
    end
  end

  describe "staff shell layout" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :staff)
    end

    test "staff user does NOT see Admin link in sidebar", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      refute html =~ "hero-shield-check"
      refute html =~ "/admin/users"
    end
  end
end
