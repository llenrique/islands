defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Board, Guesses, Rules}

  def init(name) do
    player_one = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player_two = %{name: nil, board: Board.new(), guesses: Guesses.new()}

    state = %{
      player_one: player_one,
      player_two: player_two,
      rules: Rules.new()
    }

    {:ok, state}
  end

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> _update_player_two_name(name)
      |> _update_rules(rules)
      |> _reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  defp _update_player_two_name(state, name),
    do: put_in(state.player_two.name, name)

  defp _update_rules(state, rules),
    do: %{state | rules: rules}

  defp _reply_success(state, reply), do: {:reply, reply, state}
end
