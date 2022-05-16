defmodule IslandsEngine.Board do
  @moduledoc """
  A board represents the place where players set their islands and where they
  make guesses to try to hit the other players islands. The main actions in a board are:
  1. Position islands
  2. Check for all islands positioned
  3. Make coordinate guesses
  """
  alias IslandsEngine.{Island, Coordinate}

  @doc """
  Returns an empty map that reperesents the a whole board
  """
  @spec new() :: map
  def new(), do: %{}

  @doc """
  Set an island inton the board
  """
  @spec position_island(map, atom, Island.t()) :: map | {:error, :overlapping_island}
  def position_island(board, new_key, %Island{} = new_island) do
    case _overlaps_existing_island(board, new_key, new_island) do
      true -> {:error, :overlapping_island}
      false -> Map.put(board, new_key, new_island)
    end
  end

  defp _overlaps_existing_island(board, new_key, %Island{} = new_island) do
    Enum.any?(board, fn {key, island} ->
      key != new_key and Island.overlaps?(island, new_island)
    end)
  end

  def all_islands_positioned?(board),
    do: Enum.all?(Island.types, &Map.has_key?(board, &1))

  def guess(board, %Coordinate{} = guess_coordinate) do
    board
    |> _check_all_islands(guess_coordinate)
    |> _guess_response(board)
  end

  defp _check_all_islands(board, coordinate) do
    Enum.find_value(board, :miss, fn {key, island} ->
      case Island.guess(island, coordinate) do
        {:hit, island} -> {key, island}
        :miss -> false
      end
    end)
  end

  defp _guess_response({key, island}, board) do
    board = %{board | key => island}
    {:hit, _forest_check(board, key), _win_check(board), board}
  end

  defp _guess_response(:miss, board),
    do: {:miss, :none, :no_win, board}

  defp _forest_check(board, key) do
    case _forested?(board, key) do
      true -> key
      false -> :none
    end
  end

  defp _forested?(board, key) do
    board
    |> Map.fetch!(key)
    |> Island.forested?()
  end

  defp _win_check(board) do
    case _all_forested?(board) do
      true -> :win
      false -> :no_win
    end
  end

  defp _all_forested?(board),
    do: Enum.all?(board, fn {_key, island} -> Island.forested?(island) end)
end
