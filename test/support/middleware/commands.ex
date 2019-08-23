defmodule Commander.Middleware.Commands do
  @moduledoc false

  defmodule IncrementCount do
    @moduledoc false
    defstruct uuid: nil, by: 1
    use Commander.Command
  end

  defmodule Fail do
    @moduledoc false
    defstruct [:uuid]
    use Commander.Command
  end

  defmodule RaiseError do
    @moduledoc false
    defstruct [:uuid]
    use Commander.Command
  end

  defmodule MultiRunError do
    @moduledoc false
    defstruct [:uuid]
    use Commander.Command
  end

  defmodule Timeout do
    @moduledoc false
    defstruct [:uuid]
    use Commander.Command
  end

  defmodule Validate do
    @moduledoc false
    defstruct [:uuid, :valid?]
    use Commander.Command
  end

  defmodule CommandHandler do
    @moduledoc false
    use Commander.Commands.Handler

    handle(%IncrementCount{by: by}, fn _repo, _changes ->
      {:ok, {:ok, by}}
    end)

    handle(%Fail{}, fn _repo, _changes ->
      {:error, {:error, :failed}}
    end)

    handle(%RaiseError{}, fn _repo, _changes ->
      raise "failed"
    end)

    handle(%Timeout{}, fn _repo, _changes ->
      :timer.sleep(1_000)
      {:ok, []}
    end)

    handle(%Validate{}, fn _repo, _changes ->
      {:ok, []}
    end)

    handle(%MultiRunError{}, fn _repo, _changes ->
      []
    end)
  end
end
