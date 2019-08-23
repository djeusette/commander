defmodule Commander.RouterTest do
  use ExUnit.Case

  describe "routing to command handler" do
    alias Commander.Commands.{CommandBasicTest, CommandSleepTest, CommandResultTest}

    alias Commander.Commands.Handlers.{
      CommandBasicHandlerTest,
      CommandMetadataHandlerTest,
      CommandSlowHandlerTest,
      CommandResultHandlerTest
    }

    defmodule BasicTestRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(CommandBasicTest,
        to: CommandBasicHandlerTest
      )
    end

    defmodule MetadataTestRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(CommandBasicTest,
        to: CommandMetadataHandlerTest
      )
    end

    defmodule SlowCommandHandlerTestRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(CommandSleepTest,
        to: CommandSlowHandlerTest
      )
    end

    defmodule ResultTestRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(CommandResultTest,
        to: CommandResultHandlerTest
      )
    end

    defmodule MultiDispatchRouter do
      use Commander.Router, repo: Commander.Repo

      dispatch(
        [
          CommandBasicTest,
          CommandResultTest
        ],
        to: CommandBasicHandlerTest
      )
    end

    test "should dispatch command to registered command handler" do
      assert {:ok, %{CommandBasicTest => {:ok, "Bar"}}} = BasicTestRouter.dispatch(%CommandBasicTest{foo: "Bar"})
    end

    test "should dispatch command asynchronously and return a task ref" do
      assert {:ok, %Task{}} = BasicTestRouter.dispatch(%CommandBasicTest{foo: "Bar"}, async: true)
    end

    test "should pass the metadata to the command handler" do
      metadata = %{metadata: true}

      assert {:ok, %{CommandBasicTest => {:ok, ^metadata}}} =
               MetadataTestRouter.dispatch(%CommandBasicTest{foo: "Bar"}, metadata: metadata)
    end

    test "should dispatch command synchronously and wait for the result" do
      sleep_ms = 100

      {microseconds, result} =
        :timer.tc(fn ->
          SlowCommandHandlerTestRouter.dispatch(%CommandSleepTest{sleep: sleep_ms}, timeout: 200)
        end)

      # Allow 20 milliseconds of execution
      assert abs(round(microseconds / 1000) - sleep_ms) < 20
      assert {:ok, %{CommandSleepTest => {:ok, ^sleep_ms}}} = result
    end

    test "should dispatch command synchronously and timeout" do
      sleep_ms = 1000
      timeout = 200

      {microseconds, result} =
        :timer.tc(fn ->
          SlowCommandHandlerTestRouter.dispatch(%CommandSleepTest{sleep: sleep_ms},
            timeout: timeout
          )
        end)

      # Allow 10 milliseconds of execution
      assert abs(round(microseconds / 1000) - timeout) < 10
      assert {:error, :execution_timeout} = result
    end

    test "should dispatch command asynchronously and the task should eventually contain the result" do
      sleep_ms = 100
      timeout = 200

      {microseconds, result} =
        :timer.tc(fn ->
          SlowCommandHandlerTestRouter.dispatch(%CommandSleepTest{sleep: sleep_ms},
            async: true,
            timeout: timeout
          )
        end)

      assert round(microseconds / 1000) < sleep_ms
      assert {:ok, %Task{} = task} = result
      assert {:ok, %{CommandSleepTest => {:ok, ^sleep_ms}}} = Task.await(task, timeout)
    end

    test "should dispatch command asynchronously and the task should be killed after timeout" do
      sleep_ms = 300
      timeout = 200

      {microseconds, result} =
        :timer.tc(fn ->
          SlowCommandHandlerTestRouter.dispatch(%CommandSleepTest{sleep: sleep_ms},
            async: true,
            timeout: timeout
          )
        end)

      assert round(microseconds / 1000) < sleep_ms
      assert {:ok, %Task{} = task} = result
      :timer.sleep(timeout)
      assert {:exit, :killed} = Task.yield(task)
    end

    test "should dispatch command synchronously and return :ok" do
      assert {:ok, %{CommandResultTest => :ok}} = ResultTestRouter.dispatch(%CommandResultTest{result: %{tag: :ok}})
    end

    test "should dispatch command synchronously and return {:ok, \"foo\"}" do
      assert {:ok, %{CommandResultTest => {:ok, "foo"}}} = ResultTestRouter.dispatch(%CommandResultTest{result: %{tag: :ok, value: "foo"}})
    end

    test "should dispatch command synchronously and return {:error, :executation_timeout}" do
      assert {:ok, %{CommandResultTest => {:error, :execution_timeout}}} =
               ResultTestRouter.dispatch(%CommandResultTest{result: %{tag: :error, value: :execution_timeout}})
    end

    test "should dispatch command synchronously and return {:error, :executation_failed, \"changeset\"}" do
      assert {:ok, %{CommandResultTest => {:error, :execution_failed, "changeset"}}} =
               ResultTestRouter.dispatch(%CommandResultTest{
                 result: %{tag: :error, value: :execution_failed, reason: "changeset"}
               })
    end

    test "should dispatch different commands to the same handler" do
      assert false
    end
  end
end
