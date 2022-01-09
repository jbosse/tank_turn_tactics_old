defmodule TankTurnTactics.Games.Game.TankMover do
  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Games.Tank

  def move_tank({:error, _error} = error, _game, _move_to), do: error

  def move_tank({:ok, tank, {from_x, from_y}}, game, {to_x, to_y}) do
    case game |> Game.square(to_x, to_y) do
      {:ok, %Tank{}} ->
        {:error, :square_occupied}

      {:ok, nil} ->
        from_index = (from_y - 1) * game.width + (from_x - 1)
        to_index = (to_y - 1) * game.width + (to_x - 1)

        tank = %Tank{tank | action_points: tank.action_points - 1}

        board =
          game.board
          |> List.replace_at(from_index, nil)
          |> List.replace_at(to_index, tank)

        {:ok, %Game{game | board: board}}

      error ->
        error
    end
  end
end
