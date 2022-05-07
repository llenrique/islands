defmodule IslandsEngine.Island do
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]

  defstruct [:coordinates, :hit_coordinates]

  def new(), do:
    %Island{coordinates: MapSet.new(), hit_coordinates: MapSet.new()}



  defp _offsets(:square), do: [{0,0}, {0,1}, {1,0}, {1,1}]
  defp _offsets(:atoll), do: [{0,0}, {0,1}, {1,1}, {2,0}, {2,1}]
  defp _offsets(:dot), do: [{0,0}]
  defp _offsets(:l_shape), do: [{0,0}, {1, 0}, {2,0}, {2,1}]
  defp _offsets(:s_shape), do: [{0,1}, {0,2}, {1,0}, {1,1}]
  defp _offsets(_shape), do: {:error, :invalid_island}
end
