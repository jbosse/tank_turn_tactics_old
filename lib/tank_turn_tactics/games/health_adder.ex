defmodule TankTurnTactics.Games.Game.HealthAdder do
  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Games.Tank

  def add_health({:error, _error} = error, _game), do: error

  def add_health({:ok, tank, {x, y}}, game) do
    index = (y - 1) * game.width + (x - 1)

    tank = %Tank{tank | hearts: tank.hearts + 1, action_points: tank.action_points - 3}

    board =
      game.board
      |> List.replace_at(index, tank)

    {:ok, %Game{game | board: board}}
  end
end
