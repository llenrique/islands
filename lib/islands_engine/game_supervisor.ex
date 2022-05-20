defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor

  alias IslandsEngine.Game

  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(name) do
    spec = Supervisor.child_spec(Game, start: {Game, :start_link, [name]})
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @spec stop_game(any) :: :ok | {:error, :not_found}
  def stop_game(name),
    do: DynamicSupervisor.terminate_child(__MODULE__, _pid_from_name(name))

  defp _pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
