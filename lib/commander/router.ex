defmodule Commander.Router do
  @register_params [
    :to,
    :timeout,
    :async
  ]

  defmacro __using__(_opts) do
    quote do
      require Logger

      import unquote(__MODULE__)

      @registered_commands []
      @registered_middleware []

      @default [
        middleware: [],
        async: Application.get_env(:commander, :async, false),
        dispatch_timeout: 5_000,
        metadata: %{}
      ]
    end
  end

  @doc """
  Include the given middleware module to be called before and after
  success or failure of each command dispatch

  The middleware module must implement the `Commander.Middleware` behaviour.

  Middleware modules are executed in the order they are defined.
  """
  defmacro middleware(middleware_module) do
    quote do
      @registered_middleware @registered_middleware ++ [unquote(middleware_module)]
    end
  end

  @doc """
  Configure the command, or list of commands, to be dispatched to the
  corresponding handler.
  """
  defmacro dispatch(command_module_or_modules, opts) do
    opts = parse_opts(opts, [])

    command_module_or_modules
    |> List.wrap()
    |> Enum.map(fn command_module ->
      quote do
        register(unquote(command_module), unquote(opts))
      end
    end)
  end

  defmacro register(command_module,
             to: handler,
             timeout: timeout,
             async: async
           ) do
    quote location: :keep do
      if Enum.member?(@registered_commands, unquote(command_module)) do
        raise ArgumentError,
          message:
            "Command `#{inspect(unquote(command_module))}` has already been registered in router `#{
              inspect(__MODULE__)
            }`"
      end

      # sanity check the configured modules exist
      ensure_module_exists(unquote(command_module))
      ensure_module_exists(unquote(handler))

      @registered_commands [unquote(command_module) | @registered_commands]

      def dispatch(command)
      def dispatch(%unquote(command_module){} = command), do: do_dispatch(command, [])

      def dispatch(command, timeout_or_opts)

      def dispatch(%unquote(command_module){} = command, :infinity),
        do: do_dispatch(command, timeout: :infinity)

      def dispatch(%unquote(command_module){} = command, timeout) when is_integer(timeout),
        do: do_dispatch(command, timeout: timeout)

      def dispatch(%unquote(command_module){} = command, opts),
        do: do_dispatch(command, opts)

      defp do_dispatch(%unquote(command_module){} = command, opts) do
        correlation_id = Keyword.get(opts, :correlation_id) || UUID.uuid4()
        async = fallback_if_nil(Keyword.get(opts, :async), [unquote(async), @default[:async]])
        metadata = Keyword.get(opts, :metadata) || @default[:metadata]
        timeout = Keyword.get(opts, :timeout) || unquote(timeout) || @default[:dispatch_timeout]

        alias Commander.Commands.Dispatcher
        alias Commander.Commands.Dispatcher.Payload

        payload = %Payload{
          command: command,
          command_uuid: UUID.uuid4(),
          correlation_id: correlation_id,
          async: async,
          handler_module: unquote(handler),
          timeout: timeout,
          metadata: metadata,
          middleware: @registered_middleware ++ @default[:middleware]
        }

        Dispatcher.dispatch(payload)
      end

      defp fallback_if_nil(value, alternatives)

      defp fallback_if_nil(nil, [alternative | alternatives]),
        do: fallback_if_nil(alternative, alternatives)

      defp fallback_if_nil(value, _), do: value
    end
  end

  defp parse_opts([{param, value} | opts], result) when param in @register_params do
    parse_opts(opts, [{param, value} | result])
  end

  defp parse_opts([{param, _value} | _opts], _result) do
    raise """
    unexpected dispatch parameter "#{param}"
    available params are: #{@register_params |> Enum.map(&to_string/1) |> Enum.join(", ")}
    """
  end

  defp parse_opts([], result) do
    Enum.map(@register_params, fn key -> {key, Keyword.get(result, key)} end)
  end

  def ensure_module_exists(module) do
    unless Code.ensure_compiled?(module) do
      raise "module `#{inspect(module)}` does not exist, perhaps you forgot to `alias` the namespace"
    end
  end
end
