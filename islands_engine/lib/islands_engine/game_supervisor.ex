defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor
  alias IslandsEngine.Game

  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :no_init_args, name: __MODULE__)
  end

  def start_game(player_1_name) do
    child_spec = {Game, player_1_name}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(player_1_name) do
    game_pid =
      player_1_name
      |> Game.via_tuple()
      |> GenServer.whereis()

    DynamicSupervisor.terminate_child(__MODULE__, game_pid)
  end

  @impl true
  def init(:no_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
