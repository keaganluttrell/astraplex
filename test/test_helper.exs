ExUnit.start()
ExUnit.configure(exclude: [:e2e])
Ecto.Adapters.SQL.Sandbox.mode(Astraplex.Repo, :manual)
