defmodule IslandsEngine.Board do
  alias IslandsEngine.Island

  def new(), do: %{}

  def position_island(board, key, %Island{} = island_to_position) do
    if overlaps_with_existing_islands?(board, key, island_to_position) do
      {:error, :overlapping_island}
    else
      Map.put(board, key, island_to_position)
    end
  end

  def all_islands_positioned?(board) do
    Enum.all?(Island.types(), &Map.has_key?(board, &1))
  end

  defp overlaps_with_existing_islands?(board, key, island_to_position) do
    if Map.has_key?(board, key) do
      false
    else
      board
      |> all_islands()
      |> Enum.any?(&Island.overlaps?(&1, island_to_position))
    end
  end

  defp all_islands(board), do: Map.values(board)
end
