defmodule IslandsEngine.GameTest do
  alias IslandsEngine.{Game, Coordinate}
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
    assert_rules_state(game, :initialized)
  end

  test "Add Player 2", %{game: game} do
    :ok = Game.add_player2(game, @player2_name)

    assert %{player2: %{name: @player2_name}} = state(game)
    assert_rules_state(game, :players_set)
  end

  test "Rule error -> return error", %{game: game} do
    Game.add_player2(game, @player2_name)
    assert :error == Game.add_player2(game, "Try to add player 2 another time")
  end

  describe "Position island" do
    test "Valid island", %{game: game} do
      mock_rules_state(game, :players_set)

      :ok = Game.position_island(game, :player1, :square, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      assert Map.has_key?(player1_board, :square)

      assert player1_board
             |> Map.fetch!(:square)
             |> Map.fetch!(:coordinates)
             |> MapSet.member?(%Coordinate{col: 3, row: 7})
    end

    test "Invalid shape", %{game: game} do
      mock_rules_state(game, :players_set)

      assert {:error, :invalid_island_type} = Game.position_island(game, :player2, :invalid, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :invalid)
    end

    test "Invalid coordinates", %{game: game} do
      mock_rules_state(game, :players_set)

      assert {:error, :invalid_coordinate} = Game.position_island(game, :player2, :l_shape, 7, 9)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :l_shape)
    end

    test "In invalid state", %{game: game} do
      mock_rules_state(game, :player1_turn)

      assert :error = Game.position_island(game, :player1, :square, 3, 7)

      %{player1: %{board: player1_board}} = state(game)
      refute Map.has_key?(player1_board, :l_shape)
    end
  end

  describe "Set islands" do
    setup [:complete_board, :partially_complete_board]

    test "All islands positionned -> Success", %{game: game, complete_board: complete_board} do
      mock_rules_state(game, :players_set)
      mock_board(game, complete_board, :player1)

      {:ok, board} = Game.set_islands(game, :player1)

      assert %{rules: %{player1: :islands_set}} = state(game)
      assert board == complete_board
    end

    test "Wrong state -> Error", %{
      game: game,
      complete_board: complete_board
    } do
      mock_rules_state(game, :initialized)
      mock_board(game, complete_board, :player1)

      assert :error = Game.set_islands(game, :player1)
      assert %{rules: %{player1: :islands_not_set}} = state(game)
    end

    test "Not all islands positionned -> Error", %{
      game: game,
      partially_complete_board: partially_complete_board
    } do
      mock_rules_state(game, :players_set)
      mock_board(game, partially_complete_board, :player1)

      assert {:error, :not_all_islands_positioned} = Game.set_islands(game, :player1)
      assert %{rules: %{player1: :islands_not_set}} = state(game)
    end
  end

  describe "Place Guess" do
    test "Valid Guess, Hits island and Win game", %{game: game} do
      mock_rules_state(game, :players_set)
      Game.position_island(game, :player2, :dot, 2, 3)
      mock_rules_state(game, :player1_turn)

      assert {:hit, :dot, :win} = Game.guess_coordinate(game, :player1, 2, 3)
      assert_rules_state(game, :game_over)
      %{player1: %{guesses: player1_guesses}} = state(game)
      assert MapSet.member?(player1_guesses.hits, %Coordinate{col: 2, row: 3})
    end

    test "Valid Guess, Hits island and Doesn't win game", %{game: game} do
      mock_rules_state(game, :players_set)
      Game.position_island(game, :player2, :square, 2, 3)
      mock_rules_state(game, :player1_turn)

      assert {:hit, :square, :no_win} = Game.guess_coordinate(game, :player1, 2, 3)
      assert_rules_state(game, :player2_turn)

      %{player2: %{board: player2_board_after_guess}} = state(game)

      assert player2_board_after_guess
             |> Map.get(:square)
             |> Map.get(:hit_coordinates)
             |> MapSet.member?(%Coordinate{col: 2, row: 3})

      %{player1: %{guesses: player1_guesses}} = state(game)
      assert MapSet.member?(player1_guesses.hits, %Coordinate{col: 2, row: 3})
    end

    test "Valid Guess, Doesn't hits island", %{game: game} do
      mock_rules_state(game, :player1_turn)

      assert {:miss, :none, :no_win} = Game.guess_coordinate(game, :player1, 2, 3)
      assert_rules_state(game, :player2_turn)
      %{player1: %{guesses: player1_guesses}} = state(game)
      assert MapSet.member?(player1_guesses.misses, %Coordinate{col: 2, row: 3})
    end

    test "invalid coordinates", %{game: game} do
      mock_rules_state(game, :player1_turn)
      assert {:error, :invalid_coordinate} = Game.guess_coordinate(game, :player1, 11, 3)
      assert_rules_state(game, :player1_turn)
    end

    test "Wrong state", %{game: game} do
      mock_rules_state(game, :initialized)

      assert :error = Game.guess_coordinate(game, :player1, 2, 3)
      assert_rules_state(game, :initialized)
    end
  end

  test "Complete scenario" do
    # Start Game
    {:ok, game} = Game.start_link("Patrick")
    assert_rules_state(game, :initialized)

    # Add 2nd player
    :ok = Game.add_player2(game, "Sarah")
    assert_rules_state(game, :players_set)

    # Position Islands & Set islands for player 1
    {:error, :not_all_islands_positioned} = Game.set_islands(game, :player1)
    :ok = Game.position_island(game, :player1, :atoll, 1, 1)
    :ok = Game.position_island(game, :player1, :dot, 1, 4)
    :ok = Game.position_island(game, :player1, :l_shape, 1, 5)
    :ok = Game.position_island(game, :player1, :s_shape, 5, 1)
    :ok = Game.position_island(game, :player1, :square, 5, 5)
    {:ok, _board} = Game.set_islands(game, :player1)

    # Position Islands & Set islands for player 2
    :ok = Game.position_island(game, :player2, :atoll, 3, 1)
    :ok = Game.position_island(game, :player2, :dot, 3, 4)
    :ok = Game.position_island(game, :player2, :l_shape, 3, 5)
    :ok = Game.position_island(game, :player2, :s_shape, 8, 1)
    :ok = Game.position_island(game, :player2, :square, 8, 5)
    {:ok, _board} = Game.set_islands(game, :player2)

    # Play Game
    assert_rules_state(game, :player1_turn)
    {:miss, :none, :no_win} = Game.guess_coordinate(game, :player1, 9, 8)

    assert_rules_state(game, :player2_turn)
    {:miss, :none, :no_win} = Game.guess_coordinate(game, :player2, 3, 1)

    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player1, 3, 1)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player2, 1, 1)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player1, 3, 3)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player2, 1, 3)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player1, 4, 1)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player2, 2, 1)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player1, 4, 2)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player2, 2, 2)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player1, 4, 3)
    {:hit, :atoll, :no_win} = Game.guess_coordinate(game, :player2, 2, 3)

    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player1, 3, 5)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player2, 1, 5)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player1, 3, 6)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player2, 1, 6)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player1, 3, 7)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player2, 1, 7)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player1, 4, 7)
    {:hit, :l_shape, :no_win} = Game.guess_coordinate(game, :player2, 2, 7)

    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player1, 8, 2)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player2, 5, 2)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player1, 9, 1)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player2, 6, 1)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player1, 9, 2)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player2, 6, 2)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player1, 10, 1)
    {:hit, :s_shape, :no_win} = Game.guess_coordinate(game, :player2, 7, 1)

    {:miss, :none, :no_win} = Game.guess_coordinate(game, :player1, 10, 4)
    {:miss, :none, :no_win} = Game.guess_coordinate(game, :player2, 1, 9)

    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player1, 8, 5)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player2, 5, 5)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player1, 8, 6)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player2, 5, 6)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player1, 9, 5)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player2, 6, 5)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player1, 9, 6)
    {:hit, :square, :no_win} = Game.guess_coordinate(game, :player2, 6, 6)

    # At this point, only :dot haven't been guessed, the first one to guess
    # will win the game
    {:miss, :none, :no_win} = Game.guess_coordinate(game, :player1, 7, 4)
    {:hit, :dot, :win} = Game.guess_coordinate(game, :player2, 1, 4)
  end

  defp state(game), do: :sys.get_state(game)

  defp mock_rules_state(game, mock_rules_state) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state.rules.state, mock_rules_state)
    end)
  end

  defp mock_board(game, mock_board, player) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state, [player, :board], mock_board)
    end)
  end

  defp assert_rules_state(game, expected_rules_state) do
    game_state = state(game)
    rules_state = game_state.rules.state
    assert expected_rules_state == rules_state
  end
end
