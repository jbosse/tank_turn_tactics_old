defmodule TankTurnTactics.Games.Game do
  defstruct [:width, :height, :players, :board]

  alias __MODULE__
  alias TankTurnTactics.Games.Tank
  alias TankTurnTactics.Games.Game.TankMover
  alias TankTurnTactics.Games.Game.TankShooter
  alias TankTurnTactics.Games.Game.HealthAdder
  alias TankTurnTactics.Games.Game.RangeAdder
  alias TankTurnTactics.Games.Game.HeartGifter
  alias TankTurnTactics.Games.Game.ActionPointGifter
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
        case row
             |> Enum.find_index(fn sq -> sq != nil && sq != :heart && sq.player == player end) do
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

  def add_range(%Game{} = game, %Player{} = player) do
    game
    |> player_tank(player)
    |> ensure_sufficient_action_points(3)
    |> RangeAdder.add_range(game)
  end

  def gift_heart(%Game{} = game, %Player{}, {x, _y}) when x > game.width,
    do: {:error, :out_of_bounds}

  def gift_heart(%Game{} = game, %Player{}, {_x, y}) when y > game.height,
    do: {:error, :out_of_bounds}

  def gift_heart(%Game{} = game, %Player{} = player, target_loc) do
    game
    |> player_tank(player)
    |> ensure_within_range(target_loc)
    |> HeartGifter.gift(game, target_loc)
  end

  def gift_action_point(%Game{} = game, %Player{}, {x, _y}) when x > game.width,
    do: {:error, :out_of_bounds}

  def gift_action_point(%Game{} = game, %Player{}, {_x, y}) when y > game.height,
    do: {:error, :out_of_bounds}

  def gift_action_point(%Game{} = game, %Player{} = player, target_loc) do
    game
    |> player_tank(player)
    |> ensure_within_range(target_loc)
    |> ActionPointGifter.gift(game, target_loc)
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

  def spawn_heart(%Game{} = game) do
    {nil, heart_index} =
      game.board
      |> Enum.with_index()
      |> Enum.filter(fn {sq, _index} -> sq == nil end)
      |> Enum.shuffle()
      |> Enum.at(0)

    board = game.board |> List.replace_at(heart_index, :heart)
    %Game{board: board}
  end

  def distribute_action_points(game) do
    board =
      game.board
      |> Enum.map(fn sq ->
        case sq do
          %Tank{} = tank ->
            %Tank{tank | action_points: tank.action_points + 1}

          _ ->
            sq
        end
      end)

    %Game{game | board: board}
  end

  def display(game) do
    header =
      [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z"
      ]
      |> Enum.take(game.width)
      |> Enum.reduce("   |", fn h, acc ->
        "#{acc}    #{h}    |"
      end)

    hr =
      1..game.width
      |> Enum.to_list()
      |> Enum.reduce("---|", fn _, acc ->
        "#{acc}---------|"
      end)

    y =
      1..game.height
      |> Enum.to_list()
      |> Enum.reduce("", fn y, y_acc ->
        p =
          1..game.width
          |> Enum.to_list()
          |> Enum.reduce("   |", fn x, x_acc ->
            index = (y - 1) * game.width + x - 1

            case game.board |> Enum.at(index) do
              :heart ->
                "#{x_acc}         |"

              %Tank{} = tank ->
                "#{x_acc}Player #{tank.player.id} |"

              _ ->
                "#{x_acc}         |"
            end
          end)

        h =
          1..game.width
          |> Enum.to_list()
          |> Enum.reduce(" #{y} |", fn x, x_acc ->
            index = (y - 1) * game.width + x - 1

            case game.board |> Enum.at(index) do
              :heart ->
                "#{x_acc}    H    |"

              %Tank{} = tank ->
                "#{x_acc}H: #{tank.hearts}     |"

              _ ->
                "#{x_acc}         |"
            end
          end)

        ap =
          1..game.width
          |> Enum.to_list()
          |> Enum.reduce("   |", fn x, x_acc ->
            index = (y - 1) * game.width + x - 1

            case game.board |> Enum.at(index) do
              :heart ->
                "#{x_acc}         |"

              %Tank{} = tank ->
                "#{x_acc}AP: #{tank.action_points}    |"

              _ ->
                "#{x_acc}         |"
            end
          end)

        "#{y_acc}#{p}\n#{h}\n#{ap}\n#{hr}\n"
      end)

    "#{header}\n#{hr}\n#{y}"
  end

  def get_options(game, player) do
    case player_tank(game, player) do
      {:ok, %Tank{hearts: 0}, _player_loc} ->
        %{
          move: [],
          shoot: [],
          add_health: false,
          add_range: false,
          gift_heart: [],
          gift_action_point: []
        }

      {:ok, tank, player_loc} ->
        moveable =
          if tank.action_points > 0 do
            game.board
            |> Enum.chunk_every(game.width)
            |> Enum.with_index()
            |> Enum.flat_map(fn {row, y_index} ->
              row
              |> Enum.with_index()
              |> Enum.map(fn {sq, x_index} ->
                case sq do
                  %Tank{} ->
                    nil

                  _ ->
                    x = x_index + 1
                    y = y_index + 1
                    if Tank.out_of_range(tank, player_loc, {x, y}), do: nil, else: {x, y}
                end
              end)
            end)
            |> Enum.filter(fn loc -> loc != nil end)
          else
            []
          end

        alive_within_range =
          if tank.action_points > 0 do
            game.board
            |> Enum.chunk_every(game.width)
            |> Enum.with_index()
            |> Enum.flat_map(fn {row, y_index} ->
              row
              |> Enum.with_index()
              |> Enum.map(fn {sq, x_index} ->
                case sq do
                  %Tank{player: ^player} ->
                    nil

                  %Tank{hearts: 0} ->
                    nil

                  %Tank{} ->
                    x = x_index + 1
                    y = y_index + 1
                    if Tank.out_of_range(tank, player_loc, {x, y}), do: nil, else: {x, y}

                  _ ->
                    nil
                end
              end)
            end)
            |> Enum.filter(fn loc -> loc != nil end)
          else
            []
          end

        can_give_hearts =
          game.board
          |> Enum.chunk_every(game.width)
          |> Enum.with_index()
          |> Enum.flat_map(fn {row, y_index} ->
            row
            |> Enum.with_index()
            |> Enum.map(fn {sq, x_index} ->
              case sq do
                %Tank{player: ^player} ->
                  nil

                %Tank{} ->
                  x = x_index + 1
                  y = y_index + 1
                  if Tank.out_of_range(tank, player_loc, {x, y}), do: nil, else: {x, y}

                _ ->
                  nil
              end
            end)
          end)
          |> Enum.filter(fn loc -> loc != nil end)

        %{
          move: moveable,
          shoot: alive_within_range,
          add_health: tank.action_points >= 3,
          add_range: tank.action_points >= 3,
          gift_action_point: alive_within_range,
          gift_heart: can_give_hearts
        }
    end
  end
end
