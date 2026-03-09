import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :astraplex, Astraplex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "astraplex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :astraplex, AstraplexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Am4Sa/REXaOSbFpMqbWCtvEnMlubeB3UAiMp2lqKSjSl17hc4EWalTb6Lo4A0ewi",
  server: true

# In test we don't send emails
config :astraplex, Astraplex.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Ash test configuration
config :ash, :disable_async?, true
config :ash, :missed_notifications, :ignore

# PhoenixTest configuration
config :phoenix_test, otp_app: :astraplex
