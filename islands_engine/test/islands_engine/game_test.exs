defmodule IslandsEngine.GameTest do
  alias IslandsEngine.Game
  use ExUnit.Case

  @player1_name "Frank"
  @player2_name "Suzie"

  setup do
    {:ok, game_pid} = Game.start_link(@player1_name)
    [game: game_pid]
  end

  test "At initialization", %{game: game} do
    assert %{player1: %{name: @player1_name}} = state(game)
    assert %{rules: %{state: :initialized}} = state(game)
  end

  test "Add Player 2", %{game: game} do
    :ok = Game.add_player2(game, @player2_name)

    assert %{player2: %{name: @player2_name}} = state(game)
    assert %{rules: %{state: :players_set}} = state(game)
  end

  test "Rule error -> return error", %{game: game} do
    Game.add_player2(game, @player2_name)
    assert :error == Game.add_player2(game, "Try to add player 2 another time")
  end

  defp state(game), do: :sys.get_state(game)
end
