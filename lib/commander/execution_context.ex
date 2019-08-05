defmodule Commander.ExecutionContext do
  defstruct [
    :command,
    :handler,
    :correlation_id,
    :timeout,
    :async,
    metadata: %{}
  ]

  alias __MODULE__
  alias Commander.Commands.Dispatcher.Payload

  def from_payload(%Payload{} = payload) do
    %Payload{
      command: command,
      handler_module: handler,
      correlation_id: correlation_id,
      metadata: metadata,
      timeout: timeout,
      async: async
    } = payload

    %ExecutionContext{
      command: command,
      handler: handler,
      correlation_id: correlation_id,
      metadata: metadata,
      timeout: timeout,
      async: async
    }
  end
end
