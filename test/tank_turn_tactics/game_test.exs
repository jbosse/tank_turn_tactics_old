defmodule TankTurnTactics.GameTest do
  use TankTurnTactics.DataCase

  alias TankTurnTactics.Games.Game
  alias TankTurnTactics.Players.Player

  describe "new/0" do
    test "should create a new game" do
      game = Game.new()

      assert 20 == game.width
      assert 20 == game.height
      assert [] == game.players
    end
  end

  describe "join/2" do
    test "should add a player to the game" do
      game = %Game{players: []}
      player = %Player{}

      %Game{players: [p | _]} = game |> Game.join(player)

      assert p == player
    end
  end

  describe "start/1" do
    test "should start the game" do
      player1 = %Player{id: 1}
      player2 = %Player{id: 2}
      game = %Game{width: 20, height: 20, players: [player1, player2]}

      %Game{board: board} = game |> Game.start()

      assert 400 == board |> Enum.count()
      assert 1 == board |> Enum.count(fn sq -> sq != nil && sq.player == player1 end)
      assert 1 == board |> Enum.count(fn sq -> sq != nil && sq.player == player2 end)
    end

    test "should start a player in a random cell" do
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
  end
end
