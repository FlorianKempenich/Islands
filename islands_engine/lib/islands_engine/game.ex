defmodule IslandsEngine.Game do
  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}
  use GenServer, restart: :transient

  @players [:player1, :player2]
  @timeout Application.fetch_env!(:islands_engine, :game_timeout)
  @ets_table Application.fetch_env!(:islands_engine, :game_ets_table_name)

  ######################
  ## Public interface ##
  ######################
  def start_link(player1_name) when is_binary(player1_name) do
    GenServer.start_link(__MODULE__, player1_name, name: via_tuple(player1_name))
  end

  def add_player2(game, player2_name) when is_binary(player2_name),
    do: GenServer.call(game, {:add_player2, player2_name})

  def position_island(game, player, shape, col, row) when player in @players,
    do: GenServer.call(game, {:position_island, player, shape, col, row})

  def set_islands(game, player) when player in @players,
    do: GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, col, row) when player in @players,
    do: GenServer.call(game, {:guess_coordinate, player, col, row})

  def via_tuple(player1_name),
    do: {:via, Registry, {Registry.Game, player1_name}}

  #########################
  ## Genserver Callbacks ##
  #########################
  def init(player1_name) do
    send(self(), {:set_initial_state, player1_name})
    {:ok, %{}}
  end

  defp fresh_state(player1_name) do
    %{
      player1: %{name: player1_name, board: Board.new(), guesses: Guesses.new()},
      player2: %{name: nil, board: Board.new(), guesses: Guesses.new()},
      rules: Rules.new()
    }
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

  def handle_call({:position_island, player, shape, col, row}, _, state) do
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

  def handle_call({:guess_coordinate, player, col, row}, _, state) do
    opponent_board = board(state, opponent(player))

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, guess} <- Coordinate.new(col, row),
         {
           hit_or_miss,
           type_hit,
           win_or_not,
           opponent_board
         } <- Board.guess(opponent_board, guess),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_or_not}) do
      state
      |> update_rules(rules)
      |> update_board(opponent_board, opponent(player))
      |> update_guesses(guess, hit_or_miss, player)
      |> reply_success({hit_or_miss, type_hit, win_or_not})
    else
      :error ->
        {:reply, :error, state}

      {:error, :invalid_coordinate} = error ->
        {:reply, error, state}
    end
  end

  def handle_info({:set_initial_state, player1_name}, _state) do
    game_name = player1_name

    state =
      case :ets.lookup(@ets_table, game_name) do
        [] -> fresh_state(player1_name)
        [{^game_name, state}] -> state
      end

    :ets.insert(@ets_table, {game_name, state})
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, state),
    do: {:stop, :timeout, state}

  defp update_player2_name(state, player2_name),
    do: put_in(state.player2.name, player2_name)

  defp update_rules(state, new_rules),
    do: %{state | rules: new_rules}

  defp update_board(state, board, player),
    do: put_in(state, [player, :board], board)

  defp update_guesses(state, guess_coordinate, hit_or_miss, player),
    do: update_in(state, [player, :guesses], &Guesses.add(&1, hit_or_miss, guess_coordinate))

  defp reply_success(state, reply) do
    game_name = state.player1.name
    :ets.insert(@ets_table, {game_name, state})
    {:reply, reply, state, @timeout}
  end

  defp board(state, player) when player in @players,
    do: get_in(state, [player, :board])

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
end
