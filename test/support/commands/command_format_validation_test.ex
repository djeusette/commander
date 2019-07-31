defmodule Commander.Commands.CommandFormatValidationTest do
  defstruct [:foo]

  use Commander.Command
  alias Commander.Command

  @impl Command
  def validate(changeset, _command) do
    changeset
    |> validate_format(:foo, ~r/[0-9]{1}.*/)
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
