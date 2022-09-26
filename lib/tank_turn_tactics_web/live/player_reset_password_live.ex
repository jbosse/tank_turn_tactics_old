defmodule TankTurnTacticsWeb.PlayerResetPasswordLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players

  def render(assigns) do
    ~H"""
    <.header>Reset Password</.header>

    <.simple_form id="reset_password_form" :let={f} for={@changeset} phx-submit="reset_password" phx-change="validate">
      <%= if @changeset.action == :insert do %>
        <.error message="Oops, something went wrong! Please check the errors below." />
      <% end %>
      <.input
        field={{f, :password}}
        type="password"
        label="New password"
        value={input_value(f, :password)}
        required
      />
      <.input
        field={{f, :password_confirmation}}
        type="password"
        label="Confirm new password"
        value={input_value(f, :password_confirmation)}
        required
      />
      <:actions>
        <.button phx-disable-with="Resetting...">Reset Password</.button>
      </:actions>
    </.simple_form>

    <p>
      <.link href={~p"/players/register"}>Register</.link> |
      <.link href={~p"/players/log_in"}>Log in</.link>
    </p>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_player_and_token(socket, params)

    socket =
      case socket.assigns do
        %{player: player} ->
          assign(socket, :changeset, Players.change_player_password(player))

        _ ->
          socket
      end

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  # Do not log in the player after reset password to avoid a
  # leaked token giving the player access to the account.
  def handle_event("reset_password", %{"player" => player_params}, socket) do
    case Players.reset_player_password(socket.assigns.player, player_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/players/log_in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"player" => player_params}, socket) do
    changeset = Players.change_player_password(socket.assigns.player, player_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  defp assign_player_and_token(socket, %{"token" => token}) do
    if player = Players.get_player_by_reset_password_token(token) do
      assign(socket, player: player, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end
end
