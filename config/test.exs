import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :tank_turn_tactics, TankTurnTactics.Repo,
  username: "postgres",
  password: "postgres",
  database: "tank_turn_tactics_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tank_turn_tactics, TankTurnTacticsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "V5f76yxNFiIW7qYatMv2ujCLWSw6hINj3YqlbXlajKxbjXjP0GjvlmSXqqI89BA5",
  server: false

# In test we don't send emails.
config :tank_turn_tactics, TankTurnTactics.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
