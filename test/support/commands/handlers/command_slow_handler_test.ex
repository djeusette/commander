defmodule Commander.Commands.Handlers.CommandSlowHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandSleepTest
  alias Commander.ExecutionContext

  handle(%CommandSleepTest{sleep: sleep}, fn _repos, _changes ->
    :timer.sleep(sleep)
    {:ok, {:ok, sleep}}
  end)
end
