defmodule IslandsEngine.Support.Helpers do
  alias IslandsEngine.{Island, Coordinate}

  def island(shape, up_left_col, up_left_row),
    do:
      shape
      |> Island.new(%Coordinate{col: up_left_col, row: up_left_row})
      |> extract_ok_result()

  defp extract_ok_result({:ok, res}), do: res
end
