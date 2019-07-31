defmodule Commander.Commands.Handlers.CommandExecutionContextHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandBasicTest
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandBasicTest{}, %ExecutionContext{} = context) do
    {:ok, context}
  end
end
