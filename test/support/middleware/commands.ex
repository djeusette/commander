defmodule Commander.Middleware.Commands do
  @moduledoc false

  defmodule IncrementCount do
    @moduledoc false
    defstruct uuid: nil, by: 1
  end

  defmodule Fail do
    @moduledoc false
    defstruct [:uuid]
  end

  defmodule RaiseError do
    @moduledoc false
    defstruct [:uuid]
  end

  defmodule Timeout do
    @moduledoc false
    defstruct [:uuid]
  end

  defmodule Validate do
    @moduledoc false
    defstruct [:uuid, :valid?]
  end

  defmodule CommandHandler do
    @moduledoc false
    @behaviour Commander.Commands.Handler

    def handle(%IncrementCount{by: by}, _context) do
      {:ok, by}
    end

    def handle(%Fail{}, _context) do
      {:error, :failed}
    end

    def handle(%RaiseError{}, _context) do
      raise "failed"
    end

    def handle(%Timeout{}, _context) do
      :timer.sleep(1_000)
      []
    end

    def handle(%Validate{}, _context) do
      []
    end
  end
end
