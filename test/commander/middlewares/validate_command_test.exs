defmodule Commander.Middlewares.ValidateCommandTest do
  use Commander.DataCase

  describe "ValidateCommand middleware" do
    alias Commander.Commands.CommandBasicTest
    alias Commander.Commands.Handlers.CommandBasicHandlerTest

    defmodule BasicTestRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(CommandBasicTest,
        to: CommandBasicHandlerTest
      )
    end

    test "returns an error when required attributes are missing" do
      cmd = CommandBasicTest.new(%{})
      assert {:error, :validation_failure,
             [foo: {"can't be blank", [validation: :required]}]} = BasicTestRouter.dispatch(cmd)
    end

    test "does not halt the pipeline when the command is valid" do
      cmd = CommandBasicTest.new(%{foo: "foo"})
      assert {:ok, %{Commander.Commands.CommandBasicTest => {:ok, "foo"}}} = BasicTestRouter.dispatch(cmd)
    end

    test "allows use of metadata" do
      cmd = CommandBasicTest.new(%{foo: "foo"})
      assert {:ok, %{Commander.Commands.CommandBasicTest => {:ok, "Dav"}}} = BasicTestRouter.dispatch(cmd, metadata: %{user: "Dav"})
    end
  end
end
