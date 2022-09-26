defmodule TankTurnTacticsWeb.PlayerSettingsLive do
  use TankTurnTacticsWeb, :live_view

  alias TankTurnTactics.Players

  def render(assigns) do
    ~H"""
    <.header>Change Email</.header>

    <.simple_form
      id="email_form"
      :let={f}
      for={@email_changeset}
      phx-submit="update_email"
      phx-change="validate_email"
    >
      <%= if @email_changeset.action == :insert do %>
        <.error message="Oops, something went wrong! Please check the errors below." />
      <% end %>

      <.input field={{f, :email}} type="email" label="Email" required value={input_value(f, :email)} />

      <.input
        field={{f, :current_password}}
        name="current_password"
        id="current_password_for_email"
        type="password"
        label="Current password"
        value={@email_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Email</.button>
      </:actions>
    </.simple_form>

    <.header>Change Password</.header>

    <.simple_form
      id="password_form"
      :let={f}
      for={@password_changeset}
      action={~p"/players/log_in?_action=password_updated"}
      method="post"
      phx-change="validate_password"
      phx-submit="update_password"
      phx-trigger-action={@trigger_submit}
    >
      <%= if @password_changeset.action == :insert do %>
        <.error message="Oops, something went wrong! Please check the errors below." />
      <% end %>

      <.input field={{f, :email}} type="hidden" value={@current_email} />

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
      />
      <.input
        field={{f, :current_password}}
        name="current_password"
        type="password"
        label="Confirm new password"
        for="current_password_for_password"
        id="current_password_for_password"
        value={@current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Password</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Players.update_player_email(socket.assigns.current_player, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/players/settings")}
  end

  def mount(_params, _session, socket) do
    player = socket.assigns.current_player

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, player.email)
      |> assign(:email_changeset, Players.change_player_email(player))
      |> assign(:password_changeset, Players.change_player_password(player))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    email_changeset = Players.change_player_email(socket.assigns.current_player, player_params)

    socket =
      assign(socket,
        email_changeset: Map.put(email_changeset, :action, :validate),
        email_form_current_password: password
      )

    {:noreply, socket}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Players.apply_player_email(player, password, player_params) do
      {:ok, applied_player} ->
        Players.deliver_player_update_email_instructions(
          applied_player,
          player.email,
          &url(~p"/players/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, put_flash(socket, :info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    password_changeset = Players.change_player_password(socket.assigns.current_player, player_params)

    {:noreply,
     socket
     |> assign(:password_changeset, Map.put(password_changeset, :action, :validate))
     |> assign(:current_password, password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Players.update_player_password(player, password, player_params) do
      {:ok, player} ->
        socket =
          socket
          |> assign(:trigger_submit, true)
          |> assign(:password_changeset, Players.change_player_password(player, player_params))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_changeset, changeset)}
    end
  end
end
