defmodule IslandsEngine.GameSupervisorTest do
  alias IslandsEngine.{Game, GameSupervisor}
  use ExUnit.Case
  @moduletag :capture_log

  setup do
    Application.stop(:islands_engine)
    Application.ensure_all_started(:islands_engine)
    :ok
  end

  @p1_name "Frank"
  test "Start a new game" do
    {:ok, game_pid} = GameSupervisor.start_game(@p1_name)

    game_name = Game.via_tuple(@p1_name)
    assert GenServer.whereis(game_name) == game_pid
  end

  test "Stop game" do
    {:ok, game_pid} = GameSupervisor.start_game(@p1_name)
    assert Process.alive?(game_pid)

    :ok = GameSupervisor.stop_game(@p1_name)

    refute Process.alive?(game_pid)
  end
end
