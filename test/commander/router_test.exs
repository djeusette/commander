defmodule Commander.RouterTest do
  use ExUnit.Case

  describe "routing to command handler" do
    alias Commander.Commands.{CommandBasicTest, CommandSleepTest}

    alias Commander.Commands.Handlers.{
      CommandBasicHandlerTest,
      CommandMetadataHandlerTest,
      CommandSlowHandlerTest
    }

    defmodule BasicTestRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandBasicHandlerTest
      )
    end

    defmodule MetadataTestRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandMetadataHandlerTest
      )
    end

    defmodule SlowCommandHandlerTestRouter do
      use Commander.Router

      dispatch(CommandSleepTest,
        to: CommandSlowHandlerTest
      )
    end

    test "should dispatch command to registered command handler" do
      assert {:ok, "Bar"} = BasicTestRouter.dispatch(%CommandBasicTest{foo: "Bar"})
    end

    test "should dispatch command asynchronously and return a task ref" do
      assert {:ok, %Task{}} = BasicTestRouter.dispatch(%CommandBasicTest{foo: "Bar"}, async: true)
    end

    test "should pass the metadata to the command handler" do
      metadata = %{metadata: true}

      assert {:ok, ^metadata} =
               MetadataTestRouter.dispatch(%CommandBasicTest{foo: "Bar"}, metadata: metadata)
    end

    test "should dispatch command synchronously and wait for the result" do
      sleep_ms = 100

      {microseconds, result} =
        :timer.tc(fn ->
          SlowCommandHandlerTestRouter.dispatch(%CommandSleepTest{sleep: sleep_ms}, timeout: 200)
        end)

      # Allow 10 milliseconds of execution
      assert abs(round(microseconds / 1000) - sleep_ms) < 10
      assert {:ok, ^sleep_ms} = result
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
      assert {:ok, ^sleep_ms} = Task.await(task, timeout)
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
  end
end
