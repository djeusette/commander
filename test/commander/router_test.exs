defmodule Commander.RouterTest do
  use ExUnit.Case

  describe "routing to command handler" do
    alias Commander.{ExecutionContext, Pipeline}

    alias Commander.Commands.{CommandBasicTest, CommandSleepTest, CommandResultTest}

    alias Commander.Commands.Handlers.{
      CommandBasicHandlerTest,
      CommandMetadataHandlerTest,
      CommandSlowHandlerTest,
      CommandResultHandlerTest,
      CommandExecutionContextHandlerTest
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

    defmodule ResultTestRouter do
      use Commander.Router

      dispatch(CommandResultTest,
        to: CommandResultHandlerTest
      )
    end

    defmodule DefaultExecutionContextRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandExecutionContextHandlerTest
      )
    end

    defmodule CustomExecutionContextRouter do
      use Commander.Router

      dispatch(CommandBasicTest,
        to: CommandExecutionContextHandlerTest,
        async: true,
        timeout: 5432
      )
    end

    defmodule MultiDispatchRouter do
      use Commander.Router

      dispatch(
        [
          CommandBasicTest,
          CommandResultTest
        ],
        to: CommandExecutionContextHandlerTest
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

    test "should dispatch command synchronously and return :ok" do
      assert :ok = ResultTestRouter.dispatch(%CommandResultTest{result: :ok})
    end

    test "should dispatch command synchronously and return {:ok, %Pipeline{response: :ok}}" do
      assert {:ok, %Pipeline{} = pipeline} = ResultTestRouter.dispatch(%CommandResultTest{result: :ok}, include_pipeline: true)
      assert :ok = Pipeline.response(pipeline)
    end

    test "should dispatch command synchronously and return {:ok, \"foo\"}" do
      assert {:ok, "foo"} = ResultTestRouter.dispatch(%CommandResultTest{result: {:ok, "foo"}})
    end

    test "should dispatch command synchronously and return {:ok, %Pipeline{response: {:ok, \"foo\"}}}" do
      assert {:ok, %Pipeline{} = pipeline} = ResultTestRouter.dispatch(%CommandResultTest{result: {:ok, "foo"}}, include_pipeline: true)
      assert {:ok, "foo"} = Pipeline.response(pipeline)
    end

    test "should dispatch command synchronously and return {:error, :executation_timeout}" do
      assert {:error, :execution_timeout} =
               ResultTestRouter.dispatch(%CommandResultTest{result: {:error, :execution_timeout}})
    end

    test "should dispatch command synchronously and return {:error, %Pipeline{response: {:error, :execution_timeout}}}" do
      assert {:error, %Pipeline{} = pipeline} =
               ResultTestRouter.dispatch(%CommandResultTest{result: {:error, :execution_timeout}}, include_pipeline: true)
      assert {:error, :execution_timeout} = Pipeline.response(pipeline)
    end

    test "should dispatch command synchronously and return {:error, :executation_failed, \"changeset\"}" do
      assert {:error, :execution_failed, "changeset"} =
               ResultTestRouter.dispatch(%CommandResultTest{
                 result: {:error, :execution_failed, "changeset"}
               })
    end

    test "should dispatch command synchronously and return {:error, %Pipeline{response: {:error, :execution_failed, \"changeset\"}}}" do
      assert {:error, %Pipeline{} = pipeline} =
               ResultTestRouter.dispatch(%CommandResultTest{
                 result: {:error, :execution_failed, "changeset"}
               }, include_pipeline: true)
      assert {:error, :execution_failed, "changeset"} = Pipeline.response(pipeline)
    end

    test "should dispatch command synchronously with default timeout" do
      assert {:ok, %ExecutionContext{async: false, timeout: 5000}} =
               DefaultExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"})
    end

    test "should dispatch command synchronously with custom timeout passed as integer" do
      assert {:ok, %ExecutionContext{async: false, timeout: 9320}} =
               DefaultExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, 9320)
    end

    test "should dispatch command synchronously with custom timeout passed as option" do
      assert {:ok, %ExecutionContext{async: false, timeout: 9320}} =
               DefaultExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, timeout: 9320)
    end

    test "should dispatch command asynchronously with default timeout" do
      assert {:ok, %Task{} = task} =
               DefaultExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, async: true)

      assert {:ok, %ExecutionContext{async: true, timeout: 5000}} = Task.await(task)
    end

    test "should dispatch command asynchronously with custom timeout" do
      assert {:ok, %Task{} = task} =
               DefaultExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"},
                 async: true,
                 timeout: 9111
               )

      assert {:ok, %ExecutionContext{async: true, timeout: 9111}} = Task.await(task)
    end

    test "should dispatch command asynchronously by default with custom timeout defined at router level" do
      assert {:ok, %Task{} = task} =
               CustomExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"})

      assert {:ok, %ExecutionContext{async: true, timeout: 5432}} = Task.await(task)
    end

    test "should dispatch command asynchronously by default with custom timeout defined as integer at dispatch level" do
      assert {:ok, %Task{} = task} =
               CustomExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, 1234)

      assert {:ok, %ExecutionContext{async: true, timeout: 1234}} = Task.await(task)
    end

    test "should dispatch command asynchronously by default with custom timeout defined in options at dispatch level" do
      assert {:ok, %Task{} = task} =
               CustomExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, timeout: 1235)

      assert {:ok, %ExecutionContext{async: true, timeout: 1235}} = Task.await(task)
    end

    test "should dispatch command synchronously thanks to dispatch level option" do
      assert {:ok, %ExecutionContext{async: false, timeout: 5432}} =
               CustomExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"}, async: false)
    end

    test "should dispatch command synchronously thanks to dispatch level option with custom timeout" do
      assert {:ok, %ExecutionContext{async: false, timeout: 5823}} =
               CustomExecutionContextRouter.dispatch(%CommandBasicTest{foo: "Bar"},
                 async: false,
                 timeout: 5823
               )
    end

    test "should dispatch different commands to the same handler" do
      assert {:ok,
              %ExecutionContext{
                handler: CommandExecutionContextHandlerTest,
                command: %CommandBasicTest{}
              }} = MultiDispatchRouter.dispatch(%CommandBasicTest{foo: "Bar"})

      assert {:ok,
              %ExecutionContext{
                handler: CommandExecutionContextHandlerTest,
                command: %CommandResultTest{}
              }} = MultiDispatchRouter.dispatch(%CommandResultTest{result: :ok})
    end
  end
end
