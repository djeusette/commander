defmodule Commander.Commands.Handlers.CommandSlowHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandSleepTest
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandSleepTest{sleep: sleep}, %ExecutionContext{}) do
    :timer.sleep(sleep)
    {:ok, sleep}
  end
end
