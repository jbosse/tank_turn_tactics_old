defmodule TankTurnTacticsWeb.PlayerForgotPasswordLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Forgot your password?
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.simple_form id="reset_password_form" :let={f} for={:player} phx-submit="send_email">
        <.input field={{f, :email}} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">Send password reset instructions</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_email", %{"player" => %{"email" => email}}, socket) do
    if player = Players.get_player_by_email(email) do
      Players.deliver_player_reset_password_instructions(
        player,
        &url(~p"/players/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
