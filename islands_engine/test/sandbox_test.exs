defmodule SandboxTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Guesses, Island}

  @tag :skip
  test "Sandbox" do
    IO.puts("")
    guessses = Guesses.new()
    {:ok, coord1} = Coordinate.new(10, 9)
    {:ok, coord2} = Coordinate.new(2, 2)

    # IO.inspect(guessses)

    guessses = update_in(guessses.hits, &MapSet.put(&1, coord1))
    guessses = update_in(guessses.hits, &MapSet.put(&1, coord2))
    _guessses = update_in(guessses.hits, &MapSet.put(&1, coord1))

    _island = Island.new(:square, coord1)
    |> IO.inspect()

    _island = Island.new(:dot, coord1)
    |> IO.inspect()

  end
end
