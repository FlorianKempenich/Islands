defmodule IslandsEngine.BoardTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Board, Island}

  setup do
    l_shape_at_2_4 = island(:l_shape, 4, 2)
    s_shape_at_4_3 = island(:s_shape, 4, 3)

    board =
      Board.new()
      |> Map.put(:l_shape, l_shape_at_2_4)
      |> Map.put(:s_shape, s_shape_at_4_3)

    [board: board]
  end

  test "Position non-overlapping island", %{board: board} do
    square_at_2_2 = island(:square, 2, 2)
    board = Board.position_island(board, :square, square_at_2_2)
    assert Map.get(board, :square) == square_at_2_2
  end

  test "Position overlapping island", %{board: board} do
    square_at_3_4 = island(:square, 3, 4)
    assert {:error, :overlapping_island} = Board.position_island(board, :square, square_at_3_4)
  end

  test "Override existing island", %{board: board} do
    s_shape_at_4_3_hit_at_4_4 = %Island{
      island(:s_shape, 4, 3)
      | hit_coordinates: [%Coordinate{col: 4, row: 4}]
    }

    assert Enum.empty?(board |> Map.get(:s_shape) |> Map.get(:hit_coordinates))
    board = Board.position_island(board, :s_shape, s_shape_at_4_3_hit_at_4_4)
    refute Enum.empty?(board |> Map.get(:s_shape) |> Map.get(:hit_coordinates))
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

  defp island(shape, up_left_col, up_left_row),
    do:
      shape
      |> Island.new(%Coordinate{col: up_left_col, row: up_left_row})
      |> extract_ok_result()

  defp extract_ok_result({:ok, res}), do: res
end
