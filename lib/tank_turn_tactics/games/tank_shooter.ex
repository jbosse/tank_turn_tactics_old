defmodule TankTurnTactics.Games.Game.TankShooter do
  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Games.Tank

  def shoot_tank({:error, _error} = error, _game, _target_loc), do: error

  def shoot_tank({:ok, _tank, _tank_loc}, game, {x, y}) do
    case game |> Game.square(x, y) do
      {:ok, nil} ->
        {:error, :square_unoccupied}

      {:ok, %Tank{} = target_tank} ->
        cond do
          target_tank.hearts > 0 ->
            index = (y - 1) * game.width + (x - 1)
            tank = %Tank{target_tank | hearts: target_tank.hearts - 1}
            board = game.board |> List.replace_at(index, tank)
            {:ok, %Game{game | board: board}}

          true ->
            {:error, :already_dead}
        end

      error ->
        error
    end
  end
end
