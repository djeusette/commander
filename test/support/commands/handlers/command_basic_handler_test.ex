defmodule Commander.Commands.Handlers.CommandBasicHandlerTest do
  use Commander.Commands.Handler

  alias Commander.Commands.CommandBasicTest

  handle(%CommandBasicTest{}, %{user: user}, fn _repo, _changes ->
    {:ok, {:ok, user}}
  end)

  handle(%CommandBasicTest{foo: foo}, fn _repo, _changes ->
    {:ok, {:ok, foo}}
  end)
end
