defmodule AstraplexWeb.E2ECase do
  @moduledoc """
  Base test case for E2E browser tests using PhoenixTestPlaywright.

  Tests using this case run against a real Phoenix server with Playwright
  browser automation. They are excluded from `mix test` by default and
  run in CI with `mix test --include e2e`.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use PhoenixTest.Playwright.Case

      use Phoenix.VerifiedRoutes,
        endpoint: AstraplexWeb.Endpoint,
        router: AstraplexWeb.Router,
        statics: AstraplexWeb.static_paths()
    end
  end
end
