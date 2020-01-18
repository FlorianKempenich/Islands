defmodule IslandsEngine.IslandTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Island}

  test "Valid Island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    assert {:ok, island} = Island.new(:square, upper_left)

    assert MapSet.equal?(
             island.coordinates,
             MapSet.new([
               %Coordinate{row: 1, col: 1},
               %Coordinate{row: 1, col: 2},
               %Coordinate{row: 2, col: 1},
               %Coordinate{row: 2, col: 2}
             ])
           )
  end

  test "Invalid coordinate" do
    {:ok, upper_left} = Coordinate.new(10, 1)
    assert {:error, :invalid_coordinate} = Island.new(:l_shape, upper_left)
  end
end
