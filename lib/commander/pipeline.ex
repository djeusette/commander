defmodule Commander.Pipeline do
  defstruct assigns: %{},
            correlation_id: nil,
            command: nil,
            command_uuid: nil,
            async: false,
            halted: false,
            metadata: nil,
            response: nil

  alias __MODULE__

  @type pipeline :: %Pipeline{}
  @type stage :: :before_dispatch | :after_failure | :after_dispatch
  @type middleware :: List.t()

  @doc """
  Puts the `key` with value equal to `value` into `assigns` map.
  """
  @spec assign(pipeline, atom, any) :: pipeline
  def assign(%Pipeline{assigns: assigns} = pipeline, key, value) when is_atom(key) do
    %Pipeline{pipeline | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Puts the `key` with value equal to `value` into `metadata` map.
  Note: Use of atom keys in metadata is deprecated in favour of binary strings.
  """
  @spec assign_metadata(pipeline, atom | binary, any) :: pipeline
  def assign_metadata(%Pipeline{metadata: metadata} = pipeline, key, value)
      when is_binary(key) or is_atom(key) do
    %Pipeline{pipeline | metadata: Map.put(metadata, key, value)}
  end

  @doc """
  Sets the response to be returned to the dispatch caller, unless already set.
  """
  @spec respond(pipeline, any) :: pipeline
  def respond(%Pipeline{response: nil} = pipeline, response) do
    %Pipeline{pipeline | response: response}
  end

  def respond(%Pipeline{} = pipeline, _response), do: pipeline

  @doc """
  Extract the response from the pipeline
  """
  def response(%Pipeline{response: response}), do: response

  @doc """
  Has the pipeline been halted?
  """
  @spec halted?(pipeline) :: true | false
  def halted?(%Pipeline{halted: halted}), do: halted

  @doc """
  Halts the pipeline by preventing further middleware downstream from being invoked.
  Prevents dispatch of the command if `halt` occurs in a `before_dispatch` callback.
  """
  @spec halt(pipeline) :: pipeline
  def halt(%Pipeline{} = pipeline) do
    %Pipeline{pipeline | halted: true} |> respond({:error, :halted})
  end

  @doc """
  Executes the middleware chain.
  """
  @spec chain(pipeline, stage, middleware) :: pipeline
  def chain(pipeline, stage, middleware)
  def chain(%Pipeline{} = pipeline, _stage, []), do: pipeline
  def chain(%Pipeline{halted: true} = pipeline, :before_dispatch, _middleware), do: pipeline
  def chain(%Pipeline{halted: true} = pipeline, :after_dispatch, _middleware), do: pipeline

  def chain(%Pipeline{} = pipeline, stage, [module | modules]) do
    chain(apply(module, stage, [pipeline]), stage, modules)
  end
end
