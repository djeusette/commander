defmodule Commander.Commands.Handlers.CommandExecutionContextHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.{CommandBasicTest, CommandResultTest}
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandBasicTest{}, %ExecutionContext{} = context) do
    {:ok, context}
  end

  @impl Handler
  def handle(%CommandResultTest{}, %ExecutionContext{} = context) do
    {:ok, context}
  end
end
