defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}

  @players [:player_one, :player_two]

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

  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:position_island, player}),
     {:ok, island_coordinate} <- Coordinate.new(row, col),
     {:ok, island} <- Island.new(key, island_coordinate),
     %{} = board <- Board.position_island(board, key, island) do
      state
      |> _update_board(player, board)
      |> _update_rules(rules)
      |> _reply_success(:ok)
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state}
      {:error, :overlapping_island} -> {:reply, {:error, :overlapping_island}, state}
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

  def position_island(game, player, key, row, col) when player in @players,
    do: GenServer.call(game, {:position_island, player, key, row, col})

  defp _update_board(state, player, board) do
    Map.update!(state, player, fn player ->
      %{player | board: board}
    end)
  end

  def player_board(state, player), do: Map.get(state, player).board
end
