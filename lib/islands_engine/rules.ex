defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
            player_one: :islands_not_set,
            player_two: :islands_not_set

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player),
    do: {:ok, %{rules | state: :players_set}}

  def check(%Rules{state: :players_set} = rules, {:position_island, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    case _both_players_islands_set?(rules) do
      true -> {:ok, %{rules | state: :player_one_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :player_one_turn} = rules, {:guess_coordinate, :player_one}),
    do: {:ok, %{rules | state: :player_two_turn}}

  def check(%Rules{state: :player_one_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %{rules | state: :game_over}}
    end
  end

  def check(%Rules{state: :player_two_turn} = rules, {:guess_coordinate, :player_two}),
    do: {:ok, %{rules | state: :player_one_turn}}

  def check(%Rules{state: :player_two_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %{rules | state: :game_over}}
    end
  end

  def check(_state, _action), do: :error

  defp _both_players_islands_set?(rules),
    do: rules.player_one == :islands_set && rules.player_two == :islands_set
end
