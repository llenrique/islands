defmodule IslandsEngine.Guesses do
  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:hits, :misses]

  defstruct [:hits, :misses]

  def new(), do: %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  def add(%Guesses{} = guessses, :hit, %Coordinate{} = coordinate) do
    update_in(guessses.hits, &MapSet.put(&1, coordinate))
  end

  def add(%Guesses{} = guessses, :miss, %Coordinate{} = coordinate) do
    update_in(guessses.misses, &MapSet.put(&1, coordinate))
  end
end
