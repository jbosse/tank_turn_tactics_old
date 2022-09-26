defmodule TankTurnTactics.Games.Tank do
  defstruct [:player, :hearts, :action_points, :range]

  alias __MODULE__
  alias TankTurnTactics.Players.Player

  def new(%Player{} = player) do
    %Tank{player: player, hearts: 3, action_points: 0, range: 2}
  end

  def out_of_range(tank, {x1, y1}, {x2, y2}) do
    cond do
      x1 - x2 > tank.range -> true
      x2 - x1 > tank.range -> true
      y1 - y2 > tank.range -> true
      y2 - y1 > tank.range -> true
      true -> false
    end
  end
end
