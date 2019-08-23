defmodule Commander.Commands.Handlers.CommandMetadataHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandBasicTest
  alias Commander.ExecutionContext

  handle(%CommandBasicTest{}, metadata, fn _repo, _changes ->
    {:ok, {:ok, metadata}}
  end)
end
