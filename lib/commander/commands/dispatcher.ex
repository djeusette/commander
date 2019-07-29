defmodule Commander.Commands.Dispatcher do
  defmodule Payload do
    defstruct [
      :command,
      :command_uuid,
      :correlation_id,
      :async,
      :handler_module,
      :timeout,
      :metadata,
      middleware: []
    ]
  end

  alias Commander.Pipeline
  alias Commander.Commands.Handler.ExecutionContext

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

  defp run(%Pipeline{} = pipeline, %Payload{timeout: timeout} = payload) do
    context = ExecutionContext.from_payload(payload)

    task =
      Task.Supervisor.async_nolink(
        Commander.TaskDispatcher,
        Commander.Commands.Handler,
        :execute,
        [context]
      )

    result =
      case Task.yield(task, timeout) || Task.shutdown(task) do
        {:ok, reply} -> reply
        {:exit, error} -> {:error, :execution_failed, error}
        nil -> {:error, :execution_timeout}
      end

    case result do
      :ok ->
        pipeline
        |> execute_after_dispatch(payload)
        |> Pipeline.respond(:ok)

      {:ok, any} ->
        pipeline
        |> execute_after_dispatch(payload)
        |> Pipeline.respond({:ok, any})

      {:error, error} ->
        pipeline
        |> Pipeline.respond({:error, error})
        |> execute_after_failure(payload)

      {:error, error, reason} ->
        pipeline
        |> Pipeline.assign(:error_reason, reason)
        |> Pipeline.respond({:error, error})
        |> execute_after_failure(payload)
    end
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
