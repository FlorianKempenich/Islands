defmodule IslandsEngine.Board do
  alias IslandsEngine.{Island, Coordinate}

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

  def guess(board, %Coordinate{} = guess) do
    board
    |> try_to_hit_island(guess)
    |> update_board_and_compute_response(board)
  end

  defp try_to_hit_island(board, guess) do
    Enum.find_value(board, :no_island_hit, fn {island_type, island} ->
      case Island.guess(island, guess) do
        {:hit, island} ->
          {island_type, island}

        :miss ->
          false
      end
    end)
  end

  defp update_board_and_compute_response(guess_result, board)

  defp update_board_and_compute_response(:no_island_hit, board),
    do: {:miss, :none, :no_win, board}

  defp update_board_and_compute_response({island_hit_type, island_hit}, board) do
    board = %{board | island_hit_type => island_hit}
    {:hit, island_hit_type, win_status(board), board}
  end

  defp win_status(board) do
    if board |> all_islands() |> Enum.all?(&Island.forested?/1) do
      :win
    else
      :no_win
    end
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
