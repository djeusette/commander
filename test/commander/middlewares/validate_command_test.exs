defmodule Commander.Middlewares.ValidateCommandTest do
  use ExUnit.Case

  describe "ValidateCommand middleware" do
    alias Commander.Commands.CommandBasicTest
    alias Commander.Commands.Handlers.CommandBasicHandlerTest

    defmodule BasicTestRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandBasicHandlerTest
      )
    end

    test "returns an error when required attributes are missing" do
      cmd = CommandBasicTest.new(%{})
      assert {:error, :validation_failure,
             [foo: {"can't be blank", [validation: :required]}]} = BasicTestRouter.dispatch(cmd)
    end

    test "halts the pipeline in case of error" do
      cmd = CommandBasicTest.new(%{})
      assert {:error, %Commander.Pipeline{halted: true, response: {:error, :validation_failure,
             [foo: {"can't be blank", [validation: :required]}]}}} = BasicTestRouter.dispatch(cmd, include_pipeline: true)
    end

    test "does not halt the pipeline when the command is valid" do
      cmd = CommandBasicTest.new(%{foo: "foo"})
      assert {:ok, %Commander.Pipeline{halted: false, response: {:ok, "foo"}}} = BasicTestRouter.dispatch(cmd, include_pipeline: true)
    end
  end
end
