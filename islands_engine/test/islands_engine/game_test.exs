defmodule IslandsEngine.GameTest do
  alias IslandsEngine.Game
  import IslandsEngine.Support.Fixtures
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

  describe "Position island" do
    test "Valid island", %{game: game} do
      mock_rule_state(game, :players_set)

      :ok = Game.position_island(game, :player1, :square, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      assert Map.has_key?(player1_board, :square)
    end

    test "Invalid shape", %{game: game} do
      mock_rule_state(game, :players_set)

      assert {:error, :invalid_island_type} = Game.position_island(game, :player2, :invalid, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :invalid)
    end

    test "Invalid coordinates", %{game: game} do
      mock_rule_state(game, :players_set)

      assert {:error, :invalid_coordinate} = Game.position_island(game, :player2, :l_shape, 9, 7)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :l_shape)
    end

    test "In invalid state", %{game: game} do
      mock_rule_state(game, :player1_turn)

      assert :error = Game.position_island(game, :player1, :square, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :l_shape)
    end
  end

  describe "Set islands" do
    setup [:complete_board, :partially_complete_board]

    test "All islands positionned -> Success", %{game: game, complete_board: complete_board} do
      mock_rule_state(game, :players_set)
      mock_board(game, complete_board, :player1)

      {:ok, board} = Game.set_islands(game, :player1)

      assert %{rules: %{player1: :islands_set}} = state(game)
      assert board == complete_board
    end

    test "Wrong state -> Error", %{
      game: game,
      complete_board: complete_board
    } do
      mock_rule_state(game, :initialized)
      mock_board(game, complete_board, :player1)

      assert :error = Game.set_islands(game, :player1)
      assert %{rules: %{player1: :islands_not_set}} = state(game)
    end

    test "Not all islands positionned -> Error", %{
      game: game,
      partially_complete_board: partially_complete_board
    } do
      mock_rule_state(game, :players_set)
      mock_board(game, partially_complete_board, :player1)

      assert {:error, :not_all_islands_positioned} = Game.set_islands(game, :player1)
      assert %{rules: %{player1: :islands_not_set}} = state(game)
    end
  end

  test "Complete scenario" do
    # Start Game
    {:ok, game} = Game.start_link("Patrick")
    :ok = Game.add_player2(game, "Sarah")

    # Position Islands & Set islands for player 1
    {:error, :not_all_islands_positioned} = Game.set_islands(game, :player1)
    :ok = Game.position_island(game, :player1, :atoll, 1, 1)
    :ok = Game.position_island(game, :player1, :dot, 1, 4)
    :ok = Game.position_island(game, :player1, :l_shape, 1, 5)
    :ok = Game.position_island(game, :player1, :s_shape, 5, 1)
    :ok = Game.position_island(game, :player1, :square, 5, 5)
    {:ok, _board} = Game.set_islands(game, :player1)
  end

  defp state(game), do: :sys.get_state(game)

  defp mock_rule_state(game, mock_rule_state) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state.rules.state, mock_rule_state)
    end)
  end

  defp mock_board(game, mock_board, player) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state, [player, :board], mock_board)
    end)
  end
end
