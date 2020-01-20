defmodule IslandsEngine.Game do
  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}
  use GenServer

  @players [:player1, :player2]

  ######################
  ## Public interface ##
  ######################
  def start_link(player1_name) when is_binary(player1_name) do
    GenServer.start_link(__MODULE__, player1_name)
  end

  def add_player2(game, player2_name) when is_binary(player2_name),
    do: GenServer.call(game, {:add_player2, player2_name})

  def position_island(game, player, shape, row, col) when player in @players,
    do: GenServer.call(game, {:position_island, player, shape, row, col})

  def set_islands(game, player) when player in @players,
    do: GenServer.call(game, {:set_islands, player})

  #########################
  ## Genserver Callbacks ##
  #########################
  def init(player1_name) do
    {:ok,
     %{
       player1: %{name: player1_name, board: Board.new(), guesses: Guesses.new()},
       player2: %{name: nil, board: Board.new(), guesses: Guesses.new()},
       rules: Rules.new()
     }}
  end

  def handle_call({:add_player2, player2_name}, _, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player2) do
      state
      |> update_player2_name(player2_name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  def handle_call({:position_island, player, shape, row, col}, _, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, upper_left} <- Coordinate.new(col, row),
         {:ok, island} <- Island.new(shape, upper_left),
         %{} = board <- Board.position_island(board(state, player), shape, island) do
      state
      |> update_rules(rules)
      |> update_board(board, player)
      |> reply_success(:ok)
    else
      :error ->
        {:reply, :error, state}

      {:error, _msg} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:set_islands, player}, _, state) do
    player_board = board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         {:all_pos?, true} <- {:all_pos?, Board.all_islands_positioned?(player_board)} do
      state
      |> update_rules(rules)
      |> reply_success({:ok, player_board})
    else
      :error ->
        {:reply, :error, state}

      {:all_pos?, false} ->
        {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  defp update_player2_name(state, player2_name) do
    put_in(state.player2.name, player2_name)
  end

  defp update_rules(state, new_rules) do
    %{state | rules: new_rules}
  end

  defp update_board(state, board, player) do
    put_in(state, [player, :board], board)
  end

  defp reply_success(state, reply) do
    {:reply, reply, state}
  end

  defp board(state, player) when player in @players, do: get_in(state, [player, :board])
end
