defmodule Commander.Commands.Handler do
  alias Commander.ExecutionContext

  @type command :: struct()
  @type context :: %ExecutionContext{}
  @type reason :: term()

  @callback handle(command, context) :: :ok | {:ok, any} | {:error, reason}

  defmacro __using__(_) do
    quote do
      @behaviour Commander.Commands.Handler
    end
  end

  def execute(%ExecutionContext{handler: handler, command: command} = context) do
    apply(handler, :handle, [command, context])
    |> case do
      {:error, error} -> {:error, error}
      reply -> reply
    end
  end
end
