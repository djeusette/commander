defmodule Commander.Commands.Handler do
  alias Commander.Commands.Dispatcher.Payload

  @type payload :: %Payload{}

  defmacro __using__(_) do
    quote do
      alias Commander.Commands.Dispatcher.Payload

      import unquote(__MODULE__)

      @type command :: struct()
      @type payload :: %Payload{}
      @type reason :: term()
      @type multi :: Ecto.Multi.t()
      @type multi_fn :: function()

      @spec apply_command_to_multi(command, multi, multi_fn) :: {:ok, term} | {:error, term}
      def apply_command_to_multi(command, %Ecto.Multi{} = multi, multi_fn) when is_function(multi_fn, 2) do
        try do
          apply(Ecto.Multi, :run, [multi, command.__struct__, multi_fn])
        rescue
          e -> {:error, e}
        end
      end
    end
  end

  defmacro handle(command, lambda) do
    quote do
      def handle(unquote(command) = command, metadata, multi) do
        apply_command_to_multi(command, multi, unquote(lambda))
      end
    end
  end

  defmacro handle(command, metadata, lambda) do
    quote do
      def handle(unquote(command) = command, unquote(metadata) = metadata, multi) do
        apply_command_to_multi(command, multi, unquote(lambda))
      end
    end
  end

  @spec execute(payload) :: {:ok, term} | {:error, term}
  def execute(%Payload{handler_module: handler, command: command, multi: multi, metadata: metadata}) do
    apply(handler, :handle, [command, metadata, multi])
    |> case do
      %Ecto.Multi{} = multi -> multi
      {:error, error} -> {:error, error}
    end
  end
end
