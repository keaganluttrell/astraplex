defmodule AstraplexWeb.AuthLiveTest do
  @moduledoc false
  use AstraplexWeb.ConnCase, async: true

  describe "unauthenticated access" do
    test "redirects / to /sign-in", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) =~ "/sign-in"
    end
  end

  describe "authenticated access" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn})
    end

    test "authenticated user can visit /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Welcome to Astraplex"
    end

    test "sign out via DELETE /sign-out redirects to /sign-in", %{conn: conn} do
      conn = get(conn, ~p"/sign-out")
      assert redirected_to(conn) =~ "/sign-in"
    end
  end

  describe "admin access" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn}, role: :staff)
    end

    test "staff user visiting /admin/users is redirected to /", %{conn: conn} do
      conn = get(conn, ~p"/admin/users")
      assert redirected_to(conn) == "/"
    end
  end
end
