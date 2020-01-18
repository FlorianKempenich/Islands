defmodule IslandsEngine.Coordinate do
  alias __MODULE__

  @board_range 1..10

  @enforce_keys [:col, :row]
  defstruct [:col, :row]

  def new(col, row) when col in @board_range and row in @board_range,
    do: {:ok, %Coordinate{col: col, row: row}}

  def new(_, _),
    do: {:error, :invalid_coordinate}
end
