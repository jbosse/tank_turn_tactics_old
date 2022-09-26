defmodule TankTurnTacticsWeb.PlayerConfirmationLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.header>Confirm Account</.header>

    <.simple_form :let={f} id="confirmation_form" for={:player} phx-submit="confirm_account">
      <.input field={{f, :token}} type="hidden" value={@token} />
      <:actions>
        <.button phx-disable-with="Confirming...">Confirm my account</.button>
      </:actions>
    </.simple_form>

    <p>
      <.link href={~p"/players/register"}>Register</.link>
      |
      <.link href={~p"/players/log_in"}>Log in</.link>
    </p>
    """
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, token: params["token"]), temporary_assigns: [token: nil]}
  end

  # Do not log in the player after confirmation to avoid a
  # leaked token giving the player access to the account.
  def handle_event("confirm_account", %{"player" => %{"token" => token}}, socket) do
    case Players.confirm_player(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Player confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current player and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the player themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_player: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "Player confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
