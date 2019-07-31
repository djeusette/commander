defmodule Commander.Commands.CommandResultTest do
  defstruct [:result]

  use Commander.Command
  alias Commander.Command

  @impl Command
  def validate(changeset, _command) do
    changeset
  end

  @impl Command
  def schema do
    %{result: :map}
  end

  @impl Command
  def required_keys do
    [:result]
  end
end
