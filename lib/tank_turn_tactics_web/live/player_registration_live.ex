defmodule TankTurnTacticsWeb.PlayerRegistrationLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players
  alias TankTurnTactics.Players.Player

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/players/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        :let={f}
        id="registration_form"
        for={@changeset}
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/players/log_in?_action=registered"}
        method="post"
        as={:player}
      >
        <%= if @changeset.action == :insert do %>
          <.error message="Oops, something went wrong! Please check the errors below." />
        <% end %>

        <.input field={{f, :email}} type="email" label="Email" required />
        <.input
          field={{f, :password}}
          type="password"
          label="Password"
          value={input_value(f, :password)}
          required
        />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Players.change_player_registration(%Player{})
    socket = assign(socket, changeset: changeset, trigger_submit: false)
    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  def handle_event("save", %{"player" => player_params}, socket) do
    case Players.register_player(player_params) do
      {:ok, player} ->
        {:ok, _} =
          Players.deliver_player_confirmation_instructions(
            player,
            &url(~p"/players/confirm/#{&1}")
          )

        changeset = Players.change_player_registration(player)
        {:noreply, assign(socket, trigger_submit: true, changeset: changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"player" => player_params}, socket) do
    changeset = Players.change_player_registration(%Player{}, player_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end
end
