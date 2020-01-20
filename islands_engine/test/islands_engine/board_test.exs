defmodule IslandsEngine.BoardTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Board, Island}
  import IslandsEngine.Support.{Fixtures, Helpers}

  describe "Position island" do
    setup :partially_complete_board

    test "Position non-overlapping island", %{partially_complete_board: board} do
      square_at_2_2 = island(:square, 2, 2)
      board = Board.position_island(board, :square, square_at_2_2)
      assert Map.get(board, :square) == square_at_2_2
    end

    test "Position overlapping island", %{partially_complete_board: board} do
      square_at_3_4 = island(:square, 3, 4)
      assert {:error, :overlapping_island} = Board.position_island(board, :square, square_at_3_4)
    end

    test "Override existing island", %{partially_complete_board: board} do
      s_shape_at_4_3_hit_at_4_4 = %Island{
        island(:s_shape, 4, 3)
        | hit_coordinates: [%Coordinate{col: 4, row: 4}]
      }

      assert Enum.empty?(board |> Map.get(:s_shape) |> Map.get(:hit_coordinates))
      board = Board.position_island(board, :s_shape, s_shape_at_4_3_hit_at_4_4)
      refute Enum.empty?(board |> Map.get(:s_shape) |> Map.get(:hit_coordinates))
    end
  end

  test "All islands positioned ?" do
    board =
      %{} =
      Board.new()
      |> Board.position_island(:l_shape, island(:l_shape, 1, 1))
      |> Board.position_island(:s_shape, island(:s_shape, 5, 1))
      |> Board.position_island(:atoll, island(:atoll, 3, 1))
      |> Board.position_island(:dot, island(:dot, 7, 2))

    refute Board.all_islands_positioned?(board)
    board = Board.position_island(board, :square, island(:square, 5, 8))
    assert Board.all_islands_positioned?(board)
  end

  describe "Guess" do
    setup :complete_board

    test "Unsuccessful guess", %{complete_board: board} do
      {:ok, unsuccessful_guess} = Coordinate.new(9, 9)
      assert {:miss, :none, :no_win, board} = Board.guess(board, unsuccessful_guess)
    end

    test "Successful guess, game not yet won", %{complete_board: board} do
      # This guess will hit the :square island
      {:ok, successful_guess} = Coordinate.new(5, 8)
      assert {:hit, :square, :no_win, board_after_guess} = Board.guess(board, successful_guess)

      assert board_after_guess
             |> Map.get(:square)
             |> Map.get(:hit_coordinates)
             |> MapSet.member?(successful_guess)
    end

    test "Successful guess, game won", %{complete_board: board} do
      {:hit, :atoll, :no_win, board} = Board.guess(board, %Coordinate{col: 3, row: 1})
      {:hit, :atoll, :no_win, board} = Board.guess(board, %Coordinate{col: 3, row: 3})
      {:hit, :atoll, :no_win, board} = Board.guess(board, %Coordinate{col: 4, row: 1})
      {:hit, :atoll, :no_win, board} = Board.guess(board, %Coordinate{col: 4, row: 2})
      {:hit, :atoll, :no_win, board} = Board.guess(board, %Coordinate{col: 4, row: 3})

      {:hit, :dot, :no_win, board} = Board.guess(board, %Coordinate{col: 7, row: 2})

      {:hit, :l_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 1, row: 1})
      {:hit, :l_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 1, row: 2})
      {:hit, :l_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 1, row: 3})
      {:hit, :l_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 2, row: 3})

      {:hit, :s_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 5, row: 2})
      {:hit, :s_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 6, row: 1})
      {:hit, :s_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 6, row: 2})
      {:hit, :s_shape, :no_win, board} = Board.guess(board, %Coordinate{col: 7, row: 1})

      {:hit, :square, :no_win, board} = Board.guess(board, %Coordinate{col: 5, row: 8})
      {:hit, :square, :no_win, board} = Board.guess(board, %Coordinate{col: 5, row: 9})
      {:hit, :square, :no_win, board} = Board.guess(board, %Coordinate{col: 6, row: 8})

      # At this point, the only coordinate not guessed is: (6, 9) - Square islannd
      assert {:hit, :square, :win, board} = Board.guess(board, %Coordinate{col: 6, row: 9})
    end
  end
end
