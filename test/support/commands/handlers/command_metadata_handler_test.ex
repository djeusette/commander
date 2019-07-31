defmodule Commander.Commands.Handlers.CommandMetadataHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandBasicTest
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandBasicTest{}, %ExecutionContext{metadata: metadata}) do
    {:ok, metadata}
  end
end
