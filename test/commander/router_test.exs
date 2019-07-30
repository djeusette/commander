defmodule Commander.RouterTest do
  use ExUnit.Case

  describe "routing to command handler" do
    alias Commander.Commands.CommandBasicTest
    alias Commander.Commands.Handlers.CommandBasicHandlerTest

    defmodule TestRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandBasicHandlerTest
      )
    end

    test "should dispatch command to registered command handler" do
      assert {:ok, "Bar"} = TestRouter.dispatch(%CommandBasicTest{foo: "Bar"})
    end
  end
end
