defmodule IslandsEngine.Support.Fixtures do
  alias IslandsEngine.Board
  import IslandsEngine.Support.Helpers

  def partially_complete_board(_context) do
    [
      partially_complete_board:
        Board.new()
        |> Map.put(:l_shape, island(:l_shape, 4, 2))
        |> Map.put(:s_shape, island(:s_shape, 4, 3))
    ]
  end

  def complete_board(_context) do
    [
      complete_board:
        Board.new()
        |> Board.position_island(:l_shape, island(:l_shape, 1, 1))
        |> Board.position_island(:s_shape, island(:s_shape, 5, 1))
        |> Board.position_island(:atoll, island(:atoll, 3, 1))
        |> Board.position_island(:dot, island(:dot, 7, 2))
        |> Board.position_island(:square, island(:square, 5, 8))
    ]
  end
end
