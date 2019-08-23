defmodule Commander.Router do
  @register_params [
    :to
  ]

  defmacro __using__(opts) do
    opts = opts || []

    quote location: :keep do
      require Logger

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      @opts unquote(opts)
      @repo @opts[:repo] ||
              raise("Commander.Router expects :repo to be configured")

      @registered_commands []
      @registered_middleware []

      @default [
        middleware: [
          Commander.Middlewares.ValidateCommand
        ],
        async: Application.get_env(:commander, :async, false),
        timeout: 5_000,
        include_pipeline: false,
        metadata: %{}
      ]

      @type changes :: Map.t()
      @type error :: term()
      @type reason :: term()
      @type failed_operation :: term()
      @type failed_value :: any
      @type changes_so_far :: Map.t()

      @spec dispatch(command :: struct(), opts :: keyword()) ::
        {:ok, changes} |
        {:ok, pid} |
        {:error, error} |
        {:error, :validation_failed, reason} |
        {:error, :task_exited, error} |
        {:error, :execution_timeout} |
        {:error,  failed_operation, failed_value, changes_so_far}
      def dispatch(command)
      def dispatch(commands) when is_list(commands) do
        opts = build_options([])
        do_dispatch_multiple_commands(commands, opts)
        |> run_transaction(opts)
      end
      def dispatch(command) do
        opts = build_options([])
        do_dispatch(command, opts)
        |> run_transaction(opts)
      end

      def dispatch(command, opts)
      def dispatch(commands, opts) when is_list(commands) do
        opts = build_options(opts)
        do_dispatch_multiple_commands(commands, opts)
        |> run_transaction(opts)
      end
      def dispatch(command, opts) do
        opts = build_options(opts)
        do_dispatch(command, opts)
        |> run_transaction(opts)
      end

      defp do_dispatch_multiple_commands(commands, opts) do
        correlation_id = Keyword.fetch!(opts, :correlation_id)
        initial_multi = Keyword.fetch!(opts, :multi)
        repo = Keyword.fetch!(opts, :repo)
        metadata = Keyword.fetch!(opts, :metadata)

        Enum.reduce_while(commands, initial_multi, fn (command, multi_acc) ->
          do_dispatch(command, [multi: multi_acc, correlation_id: correlation_id, metadata: metadata])
          |> case do
            %Ecto.Multi{} = multi -> {:cont, multi}
            {:error, error} -> {:halt, {:error, error}}
            {:error, error, reason} -> {:halt, {:error, error, reason}}
          end
        end)
      end

      defp run_transaction(%Ecto.Multi{} = multi, opts) do
        async = Keyword.fetch!(opts, :async)
        timeout = Keyword.fetch!(opts, :timeout)
        correlation_id = Keyword.fetch!(opts, :correlation_id)
        metadata = Keyword.fetch!(opts, :metadata)
        repo = Keyword.fetch!(opts, :repo)

        execution_context = %Commander.ExecutionContext{
          correlation_id: correlation_id,
          timeout: timeout,
          async: async,
          metadata: metadata,
          multi: multi,
          repo: repo
        }

        Commander.Commands.Runner.execute(execution_context)
      end
      defp run_transaction({:error, error}, _opts), do: {:error, error}
      defp run_transaction({:error, error, reason}, _opts), do: {:error, error, reason}

      defp build_options(opts) do
        correlation_id = Keyword.get_lazy(opts, :correlation_id, &UUID.uuid4/0)
        multi = Keyword.get_lazy(opts, :multi, &Ecto.Multi.new/0)
        repo = Keyword.get(opts, :repo, @repo)
        metadata = Keyword.get(opts, :metadata, @default[:metadata])
        async = fallback_if_nil(Keyword.get(opts, :async), [@default[:async]])
        timeout = Keyword.get(opts, :timeout, @default[:timeout])

        [
          correlation_id: correlation_id,
          multi: multi,
          repo: repo,
          metadata: metadata,
          async: async,
          timeout: timeout
        ]
      end

      defp fallback_if_nil(value, alternatives)

      defp fallback_if_nil(nil, [alternative | alternatives]),
        do: fallback_if_nil(alternative, alternatives)

      defp fallback_if_nil(nil, []), do: nil

      defp fallback_if_nil(value, _) when not is_nil(value), do: value
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
             to: handler
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

      unless function_exported?(unquote(handler), :handle, 3) do
        raise ArgumentError,
          message:
            "Command handler `#{inspect(unquote(handler))}` does not define a :handle/3 function or call the handle/2 or handle/3 macro"
      end

      @registered_commands [unquote(command_module) | @registered_commands]

      defp do_dispatch(%unquote(command_module){} = command, opts) do
        correlation_id = Keyword.fetch!(opts, :correlation_id)
        multi = Keyword.fetch!(opts, :multi)
        metadata = Keyword.fetch!(opts, :metadata)

        payload = %Commander.Commands.Dispatcher.Payload{
          command: command,
          command_uuid: UUID.uuid4(),
          correlation_id: correlation_id,
          multi: multi,
          handler_module: unquote(handler),
          metadata: metadata,
          middlewares: @registered_middleware ++ @default[:middleware]
        }

        Commander.Commands.Dispatcher.dispatch(payload)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      @doc false

      defp do_dispatch(command, _opts), do: unregistered_command(command)

      defp unregistered_command(command) do
        _ =
          Logger.error(fn ->
            "attempted to dispatch an unregistered command: #{inspect(command)}"
          end)

        {:error, :unregistered_command}
      end
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
