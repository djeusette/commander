defmodule Commander.Commands.Handlers.CommandResultHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandResultTest
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandResultTest{result: result}, %ExecutionContext{}) do
    result
  end
end
