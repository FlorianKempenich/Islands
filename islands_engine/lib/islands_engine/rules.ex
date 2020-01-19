defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
            player1: :islands_not_set,
            player2: :islands_not_set

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player),
    do: {:ok, %Rules{rules | state: :players_set}}

  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set ->
        :error

      :islands_not_set ->
        {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    both_players_islands_set = rules.player1 == :islands_set and rules.player2 == :islands_set

    rules =
      if both_players_islands_set do
        %Rules{rules | state: :player1_turn}
      else
        rules
      end

    {:ok, rules}
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}),
    do: {:ok, %Rules{rules | state: :player2_turn}}

  def check(%Rules{state: :player1_turn} = rules, {:win_check, :win}),
    do: {:ok, %Rules{rules | state: :game_over}}

  def check(%Rules{state: :player1_turn} = rules, {:win_check, :no_win}),
    do: {:ok, rules}

  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}),
    do: {:ok, %Rules{rules | state: :player1_turn}}

  def check(%Rules{state: :player2_turn} = rules, {:win_check, :win}),
    do: {:ok, %Rules{rules | state: :game_over}}

  def check(%Rules{state: :player2_turn} = rules, {:win_check, :no_win}),
    do: {:ok, rules}

  def check(_state, _action), do: :error
end
