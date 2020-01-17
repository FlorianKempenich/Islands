defmodule IslandsEngine.CoordinateTest do
  use ExUnit.Case
  alias IslandsEngine.Coordinate

  test "Valid coordinate" do
    assert {:ok, %Coordinate{row: 4, col: 5}} = Coordinate.new(4, 5)
  end
  test "Invalid coordinate" do
    assert {:error, :invalid_coordinate} = Coordinate.new(11, 5)
    assert {:error, :invalid_coordinate} = Coordinate.new(-1, 5)
  end
end
