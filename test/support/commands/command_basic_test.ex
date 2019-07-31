defmodule Commander.Commands.CommandBasicTest do
  defstruct [:foo]

  use Commander.Command
  alias Commander.Command

  @impl Command
  def validate(changeset, _command) do
    changeset
  end

  @impl Command
  def schema do
    %{foo: :string}
  end

  @impl Command
  def required_keys do
    [:foo]
  end
end
