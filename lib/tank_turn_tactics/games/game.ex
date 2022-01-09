defmodule TankTurnTactics.Games.Game do
  defstruct [:width, :height, :players, :board]

  alias __MODULE__
  alias TankTurnTactics.Games.Tank
  alias TankTurnTactics.Players.Player

  def new() do
    %Game{width: 20, height: 20, players: []}
  end

  def join(%Game{} = game, %Player{} = player) do
    %{game | players: [player | game.players]}
  end

  def start(%Game{} = game) do
    number_of_players = game.players |> Enum.count()
    size = game.width * game.height - number_of_players
    tanks = game.players |> Enum.map(fn p -> Tank.new(p) end)

    board =
      1..size
      |> Enum.to_list()
      |> Enum.map(fn _ -> nil end)
      |> Enum.concat(tanks)
      |> Enum.shuffle()

    %{game | board: board}
  end

  def location(%Game{board: board} = game, %Player{} = player) do
    loc =
      board
      |> Enum.chunk_every(game.width)
      |> Enum.with_index()
      |> Enum.reduce({0, 0}, fn {row, y_index}, acc ->
        case row |> Enum.find_index(fn sq -> sq != nil && sq.player == player end) do
          nil -> acc
          x_index -> {x_index + 1, y_index + 1}
        end
      end)

    if loc == {0, 0}, do: {:error, :player_not_found}, else: {:ok, loc}
  end

  def square(%Game{} = game, x, _y) when x > game.width, do: {:error, :out_of_bounds}
  def square(%Game{} = game, _x, y) when y > game.height, do: {:error, :out_of_bounds}

  def square(%Game{board: board} = game, x, y) do
    index = (y - 1) * game.width + (x - 1)
    {:ok, board |> Enum.at(index)}
  end

  def move(%Game{} = game, %Player{}, {x, _y}) when x > game.width, do: {:error, :out_of_bounds}
  def move(%Game{} = game, %Player{}, {_x, y}) when y > game.height, do: {:error, :out_of_bounds}

  def move(%Game{} = game, %Player{} = player, {new_x, new_y} = move_to) do
    case game |> player_tank(player) do
      {:ok, tank, move_from} ->
        case game |> Game.square(new_x, new_y) do
          {:ok, nil} ->
            cond do
              tank.action_points < 1 -> {:error, :not_enough_action_points}
              out_of_range(tank, move_from, move_to) -> {:error, :out_of_range}
              true -> move_tank(game, tank, move_from, move_to)
            end

          _ ->
            {:error, :square_occupied}
        end

      error ->
        error
    end
  end

  def shoot(%Game{} = game, %Player{}, {x, _y}) when x > game.width, do: {:error, :out_of_bounds}
  def shoot(%Game{} = game, %Player{}, {_x, y}) when y > game.height, do: {:error, :out_of_bounds}

  def shoot(%Game{} = game, %Player{} = player, target_loc) do
    case game |> player_tank(player) do
      {:ok, tank, tank_loc} ->
        cond do
          tank.action_points < 1 -> {:error, :not_enough_action_points}
          out_of_range(tank, tank_loc, target_loc) -> {:error, :out_of_range}
          true -> shoot_tank(game, target_loc)
        end

      error ->
        error
    end
  end

  defp move_tank(game, tank, {from_x, from_y}, {to_x, to_y}) do
    from_index = (from_y - 1) * game.width + (from_x - 1)
    to_index = (to_y - 1) * game.width + (to_x - 1)

    tank = %Tank{tank | action_points: tank.action_points - 1}

    board =
      game.board
      |> List.replace_at(from_index, nil)
      |> List.replace_at(to_index, tank)

    {:ok, %Game{game | board: board}}
  end

  defp shoot_tank(game, {x, y}) do
    case game |> Game.square(x, y) do
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
    end
  end

  defp player_tank(game, player) do
    case game |> Game.location(player) do
      {:ok, {x, y} = loc} ->
        {:ok, %Tank{} = tank} = game |> Game.square(x, y)
        {:ok, tank, loc}

      error ->
        error
    end
  end

  defp out_of_range(tank, {x1, y1}, {x2, y2}) do
    cond do
      x1 - x2 > tank.range -> true
      x2 - x1 > tank.range -> true
      y1 - y2 > tank.range -> true
      y2 - y1 > tank.range -> true
      true -> false
    end
  end
end
