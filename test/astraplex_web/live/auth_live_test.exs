defmodule AstraplexWeb.AuthLiveTest do
  @moduledoc false
  use AstraplexWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "unauthenticated access" do
    test "redirects / to /sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/")
    end
  end

  describe "authenticated access" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn})
    end

    test "authenticated user can visit /", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "Welcome to Astraplex"
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
end
