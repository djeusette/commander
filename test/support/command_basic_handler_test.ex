defmodule Commander.Commands.Handlers.CommandBasicHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.CommandBasicTest
  alias Commander.ExecutionContext

  def handle(%CommandBasicTest{foo: foo}, %ExecutionContext{}) do
    {:ok, foo}
  end
end
