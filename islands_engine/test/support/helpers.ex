defmodule IslandsEngine.Support.Helpers do
  alias IslandsEngine.{Island, Coordinate}

  def island(shape, up_left_col, up_left_row),
    do:
      shape
      |> Island.new(%Coordinate{col: up_left_col, row: up_left_row})
      |> extract_ok_result()

  defp extract_ok_result({:ok, res}), do: res

  def state(game), do: :sys.get_state(game)

  def mock_rules_state(game, mock_rules_state) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state.rules.state, mock_rules_state)
    end)
  end

  def mock_board(game, mock_board, player) do
    :sys.replace_state(game, fn game_state ->
      put_in(game_state, [player, :board], mock_board)
    end)
  end

  def rules_state(game) do
    state(game).rules.state
  end
end
