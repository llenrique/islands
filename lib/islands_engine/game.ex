defmodule IslandsEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient, shutdown: 5000, type: :worker

  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}

  @players [:player_one, :player_two]
  @timeout 60 * 60 * 24 * 1000

  def init(name) do
    send(self(), {:set_state, name})
    {:ok, _fresh_state(name)} # Regresa un estado donde solo esta el nombre del primer jugador
  end

  defp _fresh_state(name) do
    player_one = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player_two = %{name: nil, board: Board.new(), guesses: Guesses.new()}

    %{player_one: player_one, player_two: player_two, rules: Rules.new()}
  end

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  def handle_info({:set_state, name}, _state) do
    state =
      case :ets.lookup(:game_state, name) do
        [] -> _fresh_state(name)
        [{_key, state}] -> state
      end

    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player_one.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok


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
    board = _player_board(state, player)

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

  def handle_call({:set_islands, player}, _from, state) do
    board = _player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
    true <- Board.all_islands_positioned?(board) do
      state
      |> _update_rules(rules)
      |> _reply_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:error, {:error, :not_all_islands_positioned}, state}
    end
  end

  def handle_call({:guess_coordinate, player, col, row}, _from, state) do
    oponent = _oponent(player)
    oponent_board = _player_board(state, oponent)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
    {:ok, coordinate} <- Coordinate.new(row, col),
    {hit_or_miss, forested_island, win_status, oponent_board} <- Board.guess(oponent_board, coordinate),
    {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state
      |> _update_board(oponent, oponent_board)
      |> _update_guesses(player, coordinate, hit_or_miss)
      |> _update_rules(rules)
      |> _reply_success({hit_or_miss, forested_island, win_status})
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
    end
  end


  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  defp _update_player_two_name(state, name),
    do: put_in(state.player_two.name, name)

  defp _update_rules(state, rules),
    do: %{state | rules: rules}

  def position_island(game, player, key, row, col) when player in @players,
    do: GenServer.call(game, {:position_island, player, key, row, col})

  defp _update_board(state, player, board) do
    Map.update!(state, player, fn player ->
      %{player | board: board}
    end)
  end

  def set_islands(game, player) when player in @players,
    do: GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, row, col) when player in @players,
    do: GenServer.call(game, {:guess_coordinate, player, row, col})

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  defp _update_guesses(state, player, coordinate, hit_or_miss) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  defp _reply_success(state, reply) do
    :ets.insert(:game_state, {state.player_one.name, state})
    {:reply, reply, state, @timeout}
  end

  defp _player_board(state, player), do: Map.get(state, player).board

  defp _oponent(:player_one), do: :player_two
  defp _oponent(:player_two), do: :player_one
end
