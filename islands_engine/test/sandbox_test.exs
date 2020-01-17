defmodule SandboxTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Guesses}

  test "Sandbox" do
    guessses = Guesses.new()
    {:ok, coord1} = Coordinate.new(1, 1)
    {:ok, coord2} = Coordinate.new(2, 2)

    IO.puts("")
    IO.inspect(guessses)

    guessses = update_in(guessses.hits, &MapSet.put(&1, coord1))
    guessses = update_in(guessses.hits, &MapSet.put(&1, coord2))
    guessses = update_in(guessses.hits, &MapSet.put(&1, coord1))

    IO.inspect(guessses)
  end
end
