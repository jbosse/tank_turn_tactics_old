defmodule TankTurnTactics.Games.Game do
  defstruct [:width, :height, :players, :board]

  alias __MODULE__
  alias TankTurnTactics.Games.Tank
  alias TankTurnTactics.Games.Game.TankMover
  alias TankTurnTactics.Games.Game.TankShooter
  alias TankTurnTactics.Games.Game.HealthAdder
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

  def move(%Game{} = game, %Player{} = player, move_to) do
    game
    |> player_tank(player)
    |> ensure_within_range(move_to)
    |> ensure_sufficient_action_points(1)
    |> TankMover.move_tank(game, move_to)
  end

  def shoot(%Game{} = game, %Player{}, {x, _y}) when x > game.width, do: {:error, :out_of_bounds}
  def shoot(%Game{} = game, %Player{}, {_x, y}) when y > game.height, do: {:error, :out_of_bounds}

  def shoot(%Game{} = game, %Player{} = player, target_loc) do
    game
    |> player_tank(player)
    |> ensure_within_range(target_loc)
    |> ensure_sufficient_action_points(1)
    |> TankShooter.shoot_tank(game, target_loc)
  end

  def add_health(%Game{} = game, %Player{} = player) do
    game
    |> player_tank(player)
    |> ensure_sufficient_action_points(3)
    |> HealthAdder.add_health(game)
  end

  def player_tank(game, player) do
    case game |> Game.location(player) do
      {:ok, {x, y} = loc} ->
        {:ok, %Tank{} = tank} = game |> Game.square(x, y)
        {:ok, tank, loc}

      error ->
        error
    end
  end

  def ensure_within_range({:error, _error} = error, _move_to), do: error

  def ensure_within_range({:ok, tank, tank_location}, target_location) do
    cond do
      Tank.out_of_range(tank, tank_location, target_location) -> {:error, :out_of_range}
      true -> {:ok, tank, tank_location}
    end
  end

  def ensure_sufficient_action_points({:error, _error} = error, _points), do: error

  def ensure_sufficient_action_points({:ok, tank, tank_location}, points) do
    cond do
      tank.action_points < points -> {:error, :not_enough_action_points}
      true -> {:ok, tank, tank_location}
    end
  end
end
