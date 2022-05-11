defmodule IslandsEngine.Island do
  @moduledoc """
  An island is a group of coordinates. Also, islands have types that are same named as the shape they are. These shapes and also island types are:
  1. square
  2. atoll
  3. dot
  4. l_shape
  5. s_shape

  The main actions at an island are:

  1. Create a new island from the shape and the initial coordinate.
  2. Guess if a coordinate hits an island coordinate
  3. Check if island is forested. This is check if all island coordinates were hit.
  4. Check if an island coordinate overlaps with other island coordinate.
  """

  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]

  @type t() :: %__MODULE__{
    coordinates: Coordinate.t(),
    hit_coordinates: Coordinate.t()
  }

  defstruct [:coordinates, :hit_coordinates]

  @doc """
  Creates a new island from the given shape and a initial coordinate.
  """
  @spec new(atom(), Coordinate.t()) :: {:ok, Island.t()} | {:error, :invalid_coordinate}
  def new(type, %Coordinate{} = upper_left) do
    with [_head_offset | _tail_offset] = offsets <- _offsets(type),
         %MapSet{} = coordinates <- _create_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  # With a given shape, and the initial coordinate, creates the coordinates group for the given island type.
  @spec _create_coordinates([tuple()], Coordinate.t()) :: MapSet.value(Coordinate.t()) | {:error, :invalid_coordinate}
  defp _create_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      _add_coordinate(acc, upper_left, offset)
    end)
  end

  #
  defp _add_coordinate(
    coordinates = _island_coordinates,
    %Coordinate{row: row, col: col} = _uper_left,
    {row_offset, col_offset} = _offset
  ) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
      {:error, :invalid_coordinate} -> {:halt, {:error, :invalid_coordinate}}
    end
  end

  def guess(island, coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}
      false -> :miss
    end
  end

  def forested?(island), do: MapSet.equal?(island.coordinates, island.hit_coordinates)

  def overlaps?(existing_island, new_island),
    do: not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)


  def types, do: [:square, :atoll, :dot, :l_shape, :s_shape]

  # Return the offset corridinates of the island shape.
  @spec _offsets(atom()) :: [tuple()]
  defp _offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp _offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  defp _offsets(:dot), do: [{0, 0}]
  defp _offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp _offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp _offsets(_shape), do: {:error, :invalid_island}
end
