defmodule Commander.Commands.Dispatcher do
  defmodule Payload do
    defstruct [
      :command,
      :command_uuid,
      :correlation_id,
      :multi,
      :handler_module,
      :metadata,
      :middlewares
    ]
  end

  alias Commander.Pipeline
  alias Commander.Commands.Handler

  @type payload :: %Payload{}
  @type error :: term()
  @type multi :: Ecto.Multi.t()

  @doc """
  Dispatch the given command to the handler module
  """
  @spec dispatch(payload) :: multi | {:error, error} | {:error, error, reason :: term() }
  def dispatch(%Payload{} = payload) do
    pipeline = to_pipeline(payload)

    execute_before_dispatch(pipeline, payload)
    |> run(payload)
    |> response()
  end

  defp response(%Pipeline{} = pipeline), do: Pipeline.response(pipeline)

  defp to_pipeline(%Payload{} = payload), do: struct(Pipeline, Map.from_struct(payload))

  defp execute_before_dispatch(%Pipeline{} = pipeline, %Payload{middlewares: middlewares}) do
    Pipeline.chain(pipeline, :before_dispatch, middlewares)
  end

  defp run(pipeline, payload)

  defp run(%Pipeline{halted: true} = pipeline, %Payload{middlewares: middlewares}) do
    execute_after_failure(pipeline, middlewares)
  end

  defp run(%Pipeline{} = pipeline, %Payload{} = payload) do
    handle_command(payload)
    |> finish_pipeline(pipeline, payload)
  end

  defp handle_command(%Payload{} = payload) do
    apply(Handler, :execute, [payload])
  end

  defp finish_pipeline(%Ecto.Multi{} = multi, %Pipeline{} = pipeline, %Payload{middlewares: middlewares}) do
    pipeline
    |> execute_after_dispatch(middlewares)
    |> Pipeline.respond(multi)
  end

  defp finish_pipeline({:error, error}, %Pipeline{} = pipeline, %Payload{middlewares: middlewares}) do
    pipeline
    |> Pipeline.respond({:error, error})
    |> execute_after_failure(middlewares)
  end

  defp execute_after_dispatch(%Pipeline{} = pipeline, middlewares) do
    Pipeline.chain(pipeline, :after_dispatch, middlewares)
  end

  defp execute_after_failure(
         %Pipeline{response: {:error, error}} = pipeline,
          middlewares
       ) do

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.chain(:after_failure, middlewares)
  end

  defp execute_after_failure(
         %Pipeline{response: {:error, error, reason}} = pipeline,
         middlewares
       ) do

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.assign(:error_reason, reason)
    |> Pipeline.chain(:after_failure, middlewares)
  end

  defp execute_after_failure(%Pipeline{} = pipeline, middlewares) do
    Pipeline.chain(pipeline, :after_failure, middlewares)
  end
end
