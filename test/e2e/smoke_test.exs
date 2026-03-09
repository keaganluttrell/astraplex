defmodule AstraplexWeb.E2E.SmokeTest do
  @moduledoc false
  use AstraplexWeb.E2ECase, async: true

  @moduletag :e2e

  test "homepage loads and LiveView connects", %{conn: conn} do
    conn
    |> visit(~p"/")
    |> assert_has("body")
  end
end
