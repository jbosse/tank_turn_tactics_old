defmodule TankTurnTactics.Games.Game.TankShooter do
  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Games.Tank

  def shoot_tank({:error, _error} = error, _game, _target_loc), do: error

  def shoot_tank({:ok, player_tank, {x1, y1}}, game, {x2, y2}) do
    case game |> Game.square(x2, y2) do
      {:ok, nil} ->
        {:error, :square_unoccupied}

      {:ok, %Tank{} = target_tank} ->
        player_index = (y1 - 1) * game.width + (x1 - 1)

        player_tank = %Tank{
          player_tank
          | action_points: player_tank.action_points - 1
        }

        cond do
          target_tank.hearts > 0 ->
            target_index = (y2 - 1) * game.width + (x2 - 1)
            target_tank = %Tank{target_tank | hearts: target_tank.hearts - 1}

            board =
              game.board
              |> List.replace_at(target_index, target_tank)
              |> List.replace_at(player_index, player_tank)

            {:ok, %Game{game | board: board}}

          true ->
            {:error, :already_dead}
        end

      error ->
        error
    end
  end
end
