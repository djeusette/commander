defmodule Commander.Commands.Dispatcher do
  defmodule Payload do
    defstruct [
      :command,
      :command_uuid,
      :correlation_id,
      :async,
      :handler_module,
      :timeout,
      :async,
      :metadata,
      middleware: []
    ]
  end

  alias Commander.Pipeline
  alias Commander.ExecutionContext

  @type payload :: %Payload{}
  @type error :: term()

  @doc """
  Dispatch the given command to the handler module
  """
  @spec dispatch(payload) :: :ok | {:error, error}
  def dispatch(%Payload{} = payload) do
    pipeline = to_pipeline(payload)

    execute_before_dispatch(pipeline, payload)
    |> run(payload)
    |> Pipeline.response()
  end

  defp to_pipeline(%Payload{} = payload), do: struct(Pipeline, Map.from_struct(payload))

  defp execute_before_dispatch(%Pipeline{} = pipeline, %Payload{middleware: middleware}) do
    Pipeline.chain(pipeline, :before_dispatch, middleware)
  end

  defp run(pipeline, payload)

  defp run(%Pipeline{halted: true} = pipeline, %Payload{} = payload) do
    execute_after_failure(pipeline, payload)
  end

  defp run(%Pipeline{} = pipeline, %Payload{} = payload) do
    ExecutionContext.from_payload(payload)
    |> execute_task()
    |> finish_pipeline(pipeline, payload)
  end

  defp execute_task(%ExecutionContext{timeout: timeout, async: true} = context) do
    %Task{pid: pid} = task = start_task(context)
    :timer.kill_after(timeout, pid)
    {:ok, task}
  end

  defp execute_task(%ExecutionContext{timeout: timeout, async: false} = context) do
    task = start_task(context)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, reply} -> reply
      {:exit, error} -> {:error, :execution_failed, error}
      nil -> {:error, :execution_timeout}
    end
  end

  defp start_task(%ExecutionContext{} = context) do
    Task.Supervisor.async_nolink(
      Commander.Commands.TaskDispatcher,
      Commander.Commands.Handler,
      :execute,
      [context]
    )
  end

  defp finish_pipeline(:ok, %Pipeline{} = pipeline, %Payload{} = payload) do
    pipeline
    |> execute_after_dispatch(payload)
    |> Pipeline.respond(:ok)
  end

  defp finish_pipeline({:ok, any}, %Pipeline{} = pipeline, %Payload{} = payload) do
    pipeline
    |> execute_after_dispatch(payload)
    |> Pipeline.respond({:ok, any})
  end

  defp finish_pipeline({:error, error}, %Pipeline{} = pipeline, %Payload{} = payload) do
    pipeline
    |> Pipeline.respond({:error, error})
    |> execute_after_failure(payload)
  end

  defp finish_pipeline({:error, error, reason}, %Pipeline{} = pipeline, %Payload{} = payload) do
    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.assign(:error_reason, reason)
    |> Pipeline.respond({:error, error, reason})
    |> execute_after_failure(payload)
  end

  defp execute_after_dispatch(%Pipeline{} = pipeline, %Payload{middleware: middleware}) do
    Pipeline.chain(pipeline, :after_dispatch, middleware)
  end

  defp execute_after_failure(
         %Pipeline{response: {:error, error}} = pipeline,
         %Payload{} = payload
       ) do
    %Payload{middleware: middleware} = payload

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.chain(:after_failure, middleware)
  end

  defp execute_after_failure(
         %Pipeline{response: {:error, error, reason}} = pipeline,
         %Payload{} = payload
       ) do
    %Payload{middleware: middleware} = payload

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.assign(:error_reason, reason)
    |> Pipeline.chain(:after_failure, middleware)
  end

  defp execute_after_failure(%Pipeline{} = pipeline, %Payload{middleware: middleware}) do
    Pipeline.chain(pipeline, :after_failure, middleware)
  end
end
