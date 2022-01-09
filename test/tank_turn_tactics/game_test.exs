defmodule TankTurnTactics.GameTest do
  use ExUnit.Case, async: true

  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Games.Tank
  alias TankTurnTactics.Players.Player

  @board_3x3 1..9 |> Enum.to_list() |> Enum.map(fn _ -> nil end)
  @board_7x7 1..49 |> Enum.to_list() |> Enum.map(fn _ -> nil end)

  describe "new/0" do
    test "creates a new game" do
      game = Game.new()

      assert 20 == game.width
      assert 20 == game.height
      assert [] == game.players
    end
  end

  describe "join/2" do
    test "adds a player to the game" do
      game = %Game{players: []}
      player = %Player{}

      %Game{players: [p | _]} = game |> Game.join(player)

      assert p == player
    end
  end

  describe "start/1" do
    test "starts the game" do
      player1 = %Player{id: 1}
      player2 = %Player{id: 2}
      game = %Game{width: 20, height: 20, players: [player1, player2]}

      %Game{board: board} = game |> Game.start()

      assert 400 == board |> Enum.count()
      assert 1 == board |> Enum.count(fn sq -> sq != nil && sq.player == player1 end)
      assert 1 == board |> Enum.count(fn sq -> sq != nil && sq.player == player2 end)
    end

    test "starts each player in a random cell" do
      player1 = %Player{id: 1}
      player2 = %Player{id: 2}
      game = %Game{width: 20, height: 20, players: [player1, player2]}

      uniq_spawns =
        1..100
        |> Enum.map(fn _ ->
          %Game{board: board} = game |> Game.start()
          index1 = board |> Enum.find_index(fn sq -> sq != nil && sq.player == player1 end)
          index2 = board |> Enum.find_index(fn sq -> sq != nil && sq.player == player2 end)
          {index1, index2}
        end)
        |> Enum.uniq()

      assert 95 < uniq_spawns |> Enum.count()
    end

    test "starts each tank with 3 hearts and 0 action points" do
      player1 = %Player{id: 1}
      player2 = %Player{id: 2}
      game = %Game{width: 20, height: 20, players: [player1, player2]}

      %Game{board: board} = game |> Game.start()

      tanks = board |> Enum.reject(fn sq -> sq == nil end)

      tanks
      |> Enum.each(fn %Tank{} = tank ->
        assert 3 == tank.hearts
        assert 0 == tank.action_points
      end)
    end
  end

  describe "location/2" do
    test "returns the location of the player" do
      player = %Player{id: 1}
      tank = %Tank{player: player, hearts: 3, action_points: 0}
      board = @board_3x3 |> List.replace_at(5, tank)
      game = %Game{width: 3, height: 3, players: [player], board: board}

      assert {:ok, {3, 2}} == Game.location(game, player)
    end

    test "returns error when the player is not on the board" do
      player = %Player{id: 1}
      board = @board_3x3
      game = %Game{width: 3, height: 3, players: [player], board: board}

      assert {:error, :player_not_found} == Game.location(game, player)
    end
  end

  describe "square/2" do
    test "returns the square at the given location" do
      player = %Player{id: 1}
      tank = %Tank{player: player, hearts: 3, action_points: 0}
      board = @board_3x3 |> List.replace_at(5, tank)
      game = %Game{width: 3, height: 3, players: [player], board: board}

      assert {:ok, ^tank} = Game.square(game, 3, 2)
      assert {:ok, nil} = Game.square(game, 1, 1)
    end

    test "returns error when the location is out of bounds" do
      player = %Player{id: 1}
      board = @board_3x3
      game = %Game{width: 3, height: 3, players: [player], board: board}

      assert {:error, :out_of_bounds} == Game.square(game, 4, 2)
      assert {:error, :out_of_bounds} == Game.square(game, 2, 4)
    end
  end

  describe "move/2" do
    test "moves the player to the given location" do
      player = %Player{id: 1}
      tank = %Tank{player: player, hearts: 3, action_points: 1}
      board = @board_3x3 |> List.replace_at(5, tank)
      game = %Game{width: 3, height: 3, players: [player], board: board}

      {:ok, game} = Game.move(game, player, {1, 1})

      assert {:ok, {1, 1}} = game |> Game.location(player)
      assert {:ok, %Tank{player: ^player, action_points: 0}} = game |> Game.square(1, 1)
    end

    test "returns error when the location is out of bounds" do
      player = %Player{id: 1}
      board = @board_3x3
      game = %Game{width: 3, height: 3, players: [player], board: board}

      assert {:error, :out_of_bounds} == Game.move(game, player, {4, 2})
      assert {:error, :out_of_bounds} == Game.move(game, player, {2, 4})
    end

    test "returns error when the desired location is out of range" do
      player = %Player{id: 1}
      tank = %Tank{player: player, hearts: 3, action_points: 1, range: 2}
      board = @board_7x7 |> List.replace_at(24, tank)
      game = %Game{width: 7, height: 7, players: [player], board: board}

      assert {:error, :out_of_range} = Game.move(game, player, {7, 4})
      assert {:error, :out_of_range} = Game.move(game, player, {1, 4})
      assert {:error, :out_of_range} = Game.move(game, player, {4, 1})
      assert {:error, :out_of_range} = Game.move(game, player, {4, 7})
      assert {:error, :out_of_range} = Game.move(game, player, {1, 1})
      assert {:error, :out_of_range} = Game.move(game, player, {7, 1})
      assert {:error, :out_of_range} = Game.move(game, player, {1, 7})
      assert {:error, :out_of_range} = Game.move(game, player, {7, 7})

      assert {:ok, _} = Game.move(game, player, {2, 2})
      assert {:ok, _} = Game.move(game, player, {4, 2})
      assert {:ok, _} = Game.move(game, player, {6, 2})
      assert {:ok, _} = Game.move(game, player, {2, 4})
      assert {:ok, _} = Game.move(game, player, {6, 4})
      assert {:ok, _} = Game.move(game, player, {2, 6})
      assert {:ok, _} = Game.move(game, player, {4, 6})
      assert {:ok, _} = Game.move(game, player, {6, 6})
    end

    test "returns error when the player is not on the board" do
      player = %Player{id: 1}
      board = @board_7x7
      game = %Game{width: 7, height: 7, players: [player], board: board}

      assert {:error, :player_not_found} = Game.move(game, player, {6, 4})
    end

    test "returns error when the player does not have an action point to move" do
      player = %Player{id: 1}
      tank = %Tank{player: player, hearts: 3, action_points: 0, range: 2}
      board = @board_7x7 |> List.replace_at(24, tank)
      game = %Game{width: 7, height: 7, players: [player], board: board}

      assert {:error, :not_enough_action_points} = Game.move(game, player, {6, 4})
    end

    test "returns error when the desired location is occupied" do
      player = %Player{id: 1}

      board =
        @board_7x7
        |> List.replace_at(24, %Tank{player: player, hearts: 3, action_points: 1, range: 2})
        |> List.replace_at(26, %Tank{
          player: %Player{id: 2},
          hearts: 3,
          action_points: 2,
          range: 2
        })

      game = %Game{width: 7, height: 7, players: [player], board: board}

      assert {:error, :square_occupied} = Game.move(game, player, {6, 4})
    end
  end
end
