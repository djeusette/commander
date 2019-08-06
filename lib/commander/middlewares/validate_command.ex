defmodule Commander.Middlewares.ValidateCommand do
  @behaviour Commander.Middleware

  alias Commander.Pipeline

  def before_dispatch(%Pipeline{command: command} = pipeline) do
    case command.__struct__.valid?(command) do
      :ok ->
        pipeline

      {:error, messages} ->
        pipeline
        |> Pipeline.respond({:error, :validation_failure, messages})
        |> Pipeline.halt()
    end
  end

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end
