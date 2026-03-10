defmodule Astraplex.System.Health do
  @moduledoc "Health check resource providing system status information."

  @derive {Jason.Encoder, only: [:status, :version, :uptime_seconds, :node]}

  use Ash.Resource,
    domain: Astraplex.System,
    data_layer: :embedded,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    attribute :status, :atom do
      constraints(one_of: [:healthy, :degraded, :unhealthy])
      allow_nil?(false)
      public?(true)
    end

    attribute :version, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :uptime_seconds, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :node, :string do
      public?(true)
    end
  end

  actions do
    action :check, :struct do
      constraints(instance_of: __MODULE__)
      description("Returns current system health status")

      run(fn _input, _context ->
        {uptime_ms, _} = :erlang.statistics(:wall_clock)

        {:ok,
         %__MODULE__{
           status: :healthy,
           version: Application.spec(:astraplex, :vsn) |> to_string(),
           uptime_seconds: div(uptime_ms, 1000),
           node: Node.self() |> to_string()
         }}
      end)
    end
  end

  policies do
    policy always() do
      authorize_if(always())
    end
  end
end
