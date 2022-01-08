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

  def move(%Game{board: board} = game, %Player{} = player, move_to) do
    {:ok, {x, y}} = game |> Game.location(player)
    {:ok, tank} = game |> Game.square(x, y)

    board =
      board
      |> Enum.chunk_every(game.width)
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, y_index} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {sq, x_index} ->
          cond do
            move_to == {x_index + 1, y_index + 1} ->
              %Tank{tank | action_points: tank.action_points - 1}

            sq == nil ->
              nil

            sq.player == player ->
              nil
          end
        end)
      end)

    {:ok, %Game{game | board: board}}
  end
end
