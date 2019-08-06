defmodule Commander.Commands.Handlers.CommandResultHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.Handler
  alias Commander.Commands.CommandResultTest
  alias Commander.ExecutionContext

  @impl Handler
  def handle(%CommandResultTest{result: %{tag: tag, value: value, reason: reason}}, %ExecutionContext{}) do
    {tag, value, reason}
  end

  @impl Handler
  def handle(%CommandResultTest{result: %{tag: tag, value: value}}, %ExecutionContext{}) do
    {tag, value}
  end

  @impl Handler
  def handle(%CommandResultTest{result: %{tag: tag}}, %ExecutionContext{}) do
    tag
  end

end
