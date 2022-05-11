defmodule IslandsEngine.Coordinate do
  alias __MODULE__

  @enforce_keys [:row, :col]

  @board_range 1..10

  @type t() :: %__MODULE__{
    row: integer(),
    col: integer()
  }

  defstruct [:row, :col]

  def new(row, col) when row in @board_range and col in @board_range,
    do: {:ok, %Coordinate{row: row, col: col}}

  def new(_row, _col), do: {:error, :invalid_coordinate}
end
