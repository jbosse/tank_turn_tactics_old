defmodule TankTurnTactics.Games.Tank do
  defstruct [:player, :hearts, :action_points, :range]

  alias __MODULE__
  alias TankTurnTactics.Players.Player

  def new(%Player{} = player) do
    %Tank{player: player, hearts: 3, action_points: 0, range: 2}
  end
end
