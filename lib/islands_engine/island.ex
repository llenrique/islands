defmodule IslandsEngine.Island do
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]

  defstruct [:coordinates, :hit_coordinates]

  def new(type, %Coordinate{} = upper_left) do
    with [_head_offset | _tail_offset] = offsets <- _offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  def add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      _add_coordinate(acc, upper_left, offset)
    end)
  end

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

  # Return the offset corridinates of the island shape.
  @spec _offsets(atom()) :: [tuple()]
  defp _offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp _offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  defp _offsets(:dot), do: [{0, 0}]
  defp _offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp _offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp _offsets(_shape), do: {:error, :invalid_island}
end
