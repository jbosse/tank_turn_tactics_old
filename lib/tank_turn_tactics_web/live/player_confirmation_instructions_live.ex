defmodule TankTurnTacticsWeb.PlayerConfirmationInstructionsLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players

  def render(assigns) do
    ~H"""
    <.header>Resend confirmation instructions</.header>

    <.simple_form id="resend_confirmation_form" :let={f} for={:player} phx-submit="send_instructions">
      <.input field={{f, :email}} type="email" label="Email" required />
      <:actions>
        <.button phx-disable-with="Sending...">Resend confirmation instructions</.button>
      </:actions>
    </.simple_form>

    <p>
      <.link href={~p"/players/register"}>Register</.link> |
      <.link href={~p"/players/log_in"}>Log in</.link>
    </p>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_instructions", %{"player" => %{"email" => email}}, socket) do
    if player = Players.get_player_by_email(email) do
      Players.deliver_player_confirmation_instructions(
        player,
        &url(~p"/players/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
