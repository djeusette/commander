defmodule Commander.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Commander.Commands.TaskDispatcher}
    ]

    opts = [strategy: :one_for_one, name: Commander.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
