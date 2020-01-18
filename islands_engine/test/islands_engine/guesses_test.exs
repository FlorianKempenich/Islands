defmodule IslandsEngine.GuessesTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Guesses}

  test "Add hit" do
    {:ok, coordinate} = Coordinate.new(1, 4)
    guesses = Guesses.new()

    guesses = Guesses.add(guesses, :hit, coordinate)

    assert MapSet.member?(guesses.hits, coordinate)
  end

  test "Add miss" do
    {:ok, coordinate} = Coordinate.new(1, 4)
    guesses = Guesses.new()

    guesses = Guesses.add(guesses, :miss, coordinate)

    assert MapSet.member?(guesses.misses, coordinate)
  end
end
