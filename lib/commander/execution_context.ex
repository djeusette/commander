defmodule Commander.ExecutionContext do
  defstruct [
    :correlation_id,
    :timeout,
    :async,
    :multi,
    :repo,
    :metadata
  ]
end
