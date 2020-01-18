defmodule IslandsEngine.Island do
  alias IslandsEngine.{Coordinate, Guesses}
  alias __MODULE__

  @enforce_keys [:coordinates]
  defstruct [:coordinates, hit_coordinates: MapSet.new()]

  def new(),
    do: %Island{coordinates: MapSet.new()}

  def new(type, %Coordinate{} = upper_left) do
    with [_ | _] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates}}
    else
      error -> error
    end
  end

  def overlaps?(island1, island2) do
    not MapSet.disjoint?(island1.coordinates, island2.coordinates)
  end

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  defp add_coordinate(
         coordinates,
         %Coordinate{col: col_ul, row: row_ul},
         {col_offset, row_offset}
       ) do
    case Coordinate.new(col_ul + col_offset, row_ul + row_offset) do
      {:ok, coord} ->
        {:cont, MapSet.put(coordinates, coord)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  defp offsets(:square),
    do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]

  defp offsets(:atol),
    do: [{0, 0}, {1, 0}, {1, 1}, {0, 2}, {1, 2}]

  defp offsets(:dot),
    do: [{0, 0}]

  defp offsets(:l_shape),
    do: [{0, 0}, {0, 1}, {0, 2}, {1, 2}]

  defp offsets(:s_shape),
    do: [{1, 0}, {2, 0}, {0, 1}, {1, 1}]

  defp offsets(_),
    do: {:error, :invalid_island_type}
end
