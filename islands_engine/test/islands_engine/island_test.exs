defmodule IslandsEngine.IslandTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Island}

  describe "Valid Island" do
    test "Square" do
      {:ok, upper_left} = Coordinate.new(2, 1)
      assert {:ok, island} = Island.new(:square, upper_left)

      assert MapSet.equal?(
               island.coordinates,
               MapSet.new([
                 %Coordinate{col: 2, row: 1},
                 %Coordinate{col: 2, row: 2},
                 %Coordinate{col: 3, row: 1},
                 %Coordinate{col: 3, row: 2}
               ])
             )
    end

    test "Atol" do
      {:ok, upper_left} = Coordinate.new(2, 1)
      assert {:ok, island} = Island.new(:atol, upper_left)

      assert MapSet.equal?(
               island.coordinates,
               MapSet.new([
                 %Coordinate{col: 2, row: 1},
                 %Coordinate{col: 3, row: 1},
                 %Coordinate{col: 3, row: 2},
                 %Coordinate{col: 3, row: 3},
                 %Coordinate{col: 2, row: 3}
               ])
             )
    end

    test "Dot" do
      {:ok, upper_left} = Coordinate.new(2, 1)
      assert {:ok, island} = Island.new(:dot, upper_left)

      assert MapSet.equal?(
               island.coordinates,
               MapSet.new([
                 %Coordinate{col: 2, row: 1}
               ])
             )
    end

    test "L shape" do
      {:ok, upper_left} = Coordinate.new(2, 1)
      assert {:ok, island} = Island.new(:l_shape, upper_left)

      assert MapSet.equal?(
               island.coordinates,
               MapSet.new([
                 %Coordinate{col: 2, row: 1},
                 %Coordinate{col: 2, row: 2},
                 %Coordinate{col: 2, row: 3},
                 %Coordinate{col: 3, row: 3}
               ])
             )
    end

    test "S shape" do
      {:ok, upper_left} = Coordinate.new(2, 1)
      assert {:ok, island} = Island.new(:s_shape, upper_left)

      assert MapSet.equal?(
               island.coordinates,
               MapSet.new([
                 %Coordinate{col: 2, row: 2},
                 %Coordinate{col: 3, row: 2},
                 %Coordinate{col: 3, row: 1},
                 %Coordinate{col: 4, row: 1}
               ])
             )
    end
  end

  test "Invalid coordinate" do
    {:ok, upper_left} = Coordinate.new(10, 1)
    assert {:error, :invalid_coordinate} = Island.new(:l_shape, upper_left)
  end

  test "Overlap" do
    {:ok, point_1_1} = Coordinate.new(1, 1)
    {:ok, point_2_1} = Coordinate.new(2, 1)

    {:ok, l_shape_at_1_1} = Island.new(:l_shape, point_1_1)
    {:ok, l_shape_at_2_1} = Island.new(:l_shape, point_2_1)
    {:ok, square_at_2_1} = Island.new(:square, point_2_1)

    assert Island.overlaps?(l_shape_at_1_1, l_shape_at_2_1)
    refute Island.overlaps?(l_shape_at_1_1, square_at_2_1)
  end

  test "Guess" do
    {:ok, upper_left} = Coordinate.new(2, 1)
    {:ok, island} = Island.new(:l_shape, upper_left)

    {:ok, hit_guess} = Coordinate.new(2, 2)
    {:ok, miss_guess} = Coordinate.new(7, 5)

    assert :miss = Island.guess(island, miss_guess)
    assert {:hit, island_after_guess} = Island.guess(island, hit_guess)
    assert MapSet.member?(island_after_guess.hit_coordinates, hit_guess)
  end

  test "Island is marked as FORESTED once all coordinates have been hit" do
    {:ok, upper_left} = Coordinate.new(2, 1)
    {:ok, island} = Island.new(:l_shape, upper_left)

    # Hit all coordinates except {3, 3}
    {:hit, island} = Island.guess(island, %Coordinate{col: 2, row: 1})
    {:hit, island} = Island.guess(island, %Coordinate{col: 2, row: 2})
    {:hit, island} = Island.guess(island, %Coordinate{col: 2, row: 3})

    refute Island.forested?(island)
    {:hit, island} = Island.guess(island, %Coordinate{col: 3, row: 3})
    assert Island.forested?(island)
  end
end
