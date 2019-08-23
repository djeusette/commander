defmodule Commander.Commands.Handlers.CommandResultHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandResultTest
  alias Commander.ExecutionContext

  handle(%CommandResultTest{result: %{tag: tag, value: value, reason: reason}}, fn _repos, _changes ->
    {:ok, {tag, value, reason}}
  end)

  handle(%CommandResultTest{result: %{tag: tag, value: value}}, fn _repos, _changes ->
    {:ok, {tag, value}}
  end)

  handle(%CommandResultTest{result: %{tag: tag}}, fn _repos, _changes ->
    {:ok, tag}
  end)
end
