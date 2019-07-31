defmodule Commander.Commands.CommandSleepTest do
  defstruct [:sleep]

  use Commander.Command
  alias Commander.Command

  @impl Command
  def validate(changeset, _command) do
    changeset
  end

  @impl Command
  def schema do
    %{sleep: :integer}
  end

  @impl Command
  def required_keys do
    [:sleep]
  end
end
