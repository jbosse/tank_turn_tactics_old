defmodule TankTurnTacticsWeb.PlayerForgotPasswordLiveTest do
  use TankTurnTacticsWeb.ConnCase

  import Phoenix.LiveViewTest
  import TankTurnTactics.PlayersFixtures

  alias TankTurnTactics.Players
  alias TankTurnTactics.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/players/reset_password")

      assert html =~ "Forgot your password?"
      assert html =~ "Register</a>"
      assert html =~ "Log in</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_player(player_fixture())
        |> live(~p"/players/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{player: player_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", player: %{"email" => player.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Players.PlayerToken, player_id: player.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", player: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Players.PlayerToken) == []
    end
  end
end
