![Tests](https://github.com/jbosse/tank_turn_tactics/actions/workflows/elixir.yml/badge.svg)

# TankTurnTactics
For fun I am attempting to implement the game described in the GDC 2013 talk by Luke Muscat from Halfbrick Studios.
https://youtu.be/t9WMNuyjm4w

## Rules
* All players start at a random location on the grid, and have 3 hearts and 0 Action Points
* Every 24 hours each player will receive 1 Action Point (AP)
* At any time you like, you can do one of the four following actions.
  1. Move to an adjacent, unoccupied square (1 AP)
  1. Shoot someone who is within your range (1 AP). Shooting someone removes 1 heart from their health.
  1. Add a heart (3 AP)
  1. Upgrade your range (3 AP)
* At the start of the game, everyone has a range of 2. That is they can shoot or trade with someone within 2 squares of them. Upgrading your shooting range increases this by 1 square each time.
* If a players reduced to 0 hearts then they are dead. Any action points the dead player had are transferred to the player who killed them. Dead players remain on the board and are not removed.
* Players are able to send gifts of hearts or action points to any player currently within their range.
* Dead players can have a heart sent to them. This will revive that player who will have 1 heart and 0 AP.

## Additional Stuff
* Dead players form a jury. Each day they vote, and whoever receives most votes will be haunted and not receive any AP that day.
* Once a day at a random time, a heart will spawn on the field. The first player to move in the square containing the heart will receive an additional heart.
* The game ends when a clear 1st 2nd and 3rd place can be determined. Once there are 4 players left we will see if they can agree on the placing.
* Action points are secret. Probably a good idea to try and hide how many you have.
* You can’t win this game without making some friends and stabbing some backs. Probably.

# Development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
