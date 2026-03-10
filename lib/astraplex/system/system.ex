defmodule Astraplex.System do
  @moduledoc "System domain for health checks and operational diagnostics."

  use Ash.Domain, extensions: [AshAi]

  tools do
    tool(:check_health, Astraplex.System.Health, :check)
  end
end
