defmodule TankTurnTactics.TankTest do
  use ExUnit.Case, async: true

  alias TankTurnTactics.Games.Tank
  alias TankTurnTactics.Players.Player

  describe "new/0" do
    test "creates a new tank" do
      player1 = %Player{id: 1}

      tank = Tank.new(player1)

      assert player1 == tank.player
      assert 3 == tank.hearts
      assert 0 == tank.action_points
      assert 2 == tank.range
    end
  end
end
