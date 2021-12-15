defmodule TankTurnTactics.Repo do
  use Ecto.Repo,
    otp_app: :tank_turn_tactics,
    adapter: Ecto.Adapters.Postgres
end
