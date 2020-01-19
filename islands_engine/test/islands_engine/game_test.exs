defmodule IslandsEngine.GameTest do
  alias IslandsEngine.Game
  alias IslandsEngine.Rules
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

  test "Position island", %{game: game} do
    mock_rule_state(game, :players_set)

    :ok = Game.position_island(game, :player1, :square, 3, 7)

    %{player1: %{board: player1_board}} = state(game)
    assert Map.has_key?(player1_board, :square)
  end

  test "Position island - Invalid shape", %{game: game} do
    mock_rule_state(game, :players_set)

    assert {:error, :invalid_island_type} = Game.position_island(game, :player2, :invalid, 3, 7)

    %{player1: %{board: player1_board}} = state(game)
    refute Map.has_key?(player1_board, :invalid)
  end

  test "Position island - Invalid coordinates", %{game: game} do
    mock_rule_state(game, :players_set)

    assert {:error, :invalid_coordinate} = Game.position_island(game, :player2, :l_shape, 9, 7)

    %{player1: %{board: player1_board}} = state(game)
    refute Map.has_key?(player1_board, :l_shape)
  end

  test "Position island - In invalid state", %{game: game} do
    mock_rule_state(game, :player1_turn)

    assert :error = Game.position_island(game, :player1, :square, 3, 7)

    %{player1: %{board: player1_board}} = state(game)
    refute Map.has_key?(player1_board, :l_shape)
  end

  defp state(game), do: :sys.get_state(game)

  defp mock_rule_state(game, mock_rule_state) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state.rules.state, mock_rule_state)
    end)
  end
end
