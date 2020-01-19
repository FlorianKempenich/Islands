defmodule IslandsEngine.RulesTest do
  use ExUnit.Case
  alias IslandsEngine.Rules

  describe "State: :initialized =>" do
    test "Action: :add_player -> Move to :players_set" do
      rules = %Rules{state: :initialized}

      {:ok, rules} = Rules.check(rules, :add_player)
      assert rules.state == :players_set
    end

    test "Action: NOT :add_player -> :error" do
      rules = %Rules{state: :initialized}
      assert :error = Rules.check(rules, :something_else)
    end
  end

  describe "State: :players_set =>" do
    test "One player position islands -> Stay in :players_set" do
      rules = %Rules{state: :players_set}
      assert {:ok, ^rules} = Rules.check(rules, {:position_islands, :player1})
    end

    test "A player tries to position their islands after they've been set already -> Error" do
      rules = %Rules{state: :players_set, player1: :islands_set}
      assert :error = Rules.check(rules, {:position_islands, :player1})
    end

    test "Set islands for one player -> Stay in :players_set" do
      rules = %Rules{state: :players_set}
      {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      assert rules.player1 == :islands_set
    end

    test "Set islands for both player -> Move to :player1_turn" do
      rules = %Rules{state: :players_set}
      {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
      assert rules.state == :player1_turn
    end
  end

  describe "State: :player1_turn" do
    test "After :player1 guesses coordinate, it's :player2's turn" do
      rules = %Rules{state: :player1_turn}
      assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})
      assert rules.state == :player2_turn
    end

    test "Only :player1 can play" do
      rules = %Rules{state: :player1_turn}
      assert :error = Rules.check(rules, {:guess_coordinate, :player2})
    end

    test "Check win -> Player 1 won the game -> Move to :game_over" do
      rules = %Rules{state: :player1_turn}
      {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end

    test "Check win -> Player 1 didn't win the game -> Stay in :player1_turn" do
      rules = %Rules{state: :player1_turn}
      assert {:ok, ^rules} = Rules.check(rules, {:win_check, :no_win})
    end
  end

  describe "State: :player2_turn" do
    test "After :player2 guesses coordinate, it's :player1's turn" do
      rules = %Rules{state: :player2_turn}
      assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})
      assert rules.state == :player1_turn
    end

    test "Only :player2 can play" do
      rules = %Rules{state: :player2_turn}
      assert :error = Rules.check(rules, {:guess_coordinate, :player1})
    end

    test "Check win -> Player 2 won the game -> Move to :game_over" do
      rules = %Rules{state: :player2_turn}
      {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end

    test "Check win -> Player 2 didn't win the game -> Stay in :player2_turn" do
      rules = %Rules{state: :player2_turn}
      assert {:ok, ^rules} = Rules.check(rules, {:win_check, :no_win})
    end
  end

  test "Complete scenario" do
    # Initialization
    rules = Rules.new()
    assert rules.state == :initialized

    # Adding the players
    {:ok, rules} = Rules.check(rules, :add_player)
    assert rules.state == :players_set

    # Position & set islands
    {:ok, rules} = Rules.check(rules, {:position_islands, :player1})
    assert rules.state == :players_set

    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set

    {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
    assert rules.state == :players_set
    assert :error = Rules.check(rules, {:position_islands, :player1})

    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set

    {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
    assert rules.state == :player1_turn

    # Play turns
    assert :error = Rules.check(rules, {:guess_coordinate, :player2})
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})
    assert rules.state == :player2_turn

    assert :error = Rules.check(rules, {:guess_coordinate, :player1})
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})
    assert rules.state == :player1_turn

    {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
    assert rules.state == :player1_turn

    # Game Won
    {:ok, rules} = Rules.check(rules, {:win_check, :win})
    assert rules.state == :game_over
  end
end
