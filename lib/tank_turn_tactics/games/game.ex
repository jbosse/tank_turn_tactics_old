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
    board
    |> Enum.chunk_every(game.width)
    |> Enum.with_index()
    |> Enum.reduce({0, 0}, fn {row, y_index}, acc ->
      case row |> Enum.find_index(fn sq -> sq != nil && sq.player == player end) do
        nil -> acc
        x_index -> {x_index + 1, y_index + 1}
      end
    end)
  end

  def square(%Game{board: board} = game, x, y) do
    index = (y - 1) * game.width + (x - 1)
    board |> Enum.at(index)
  end
end
