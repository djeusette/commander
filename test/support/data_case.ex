defmodule Commander.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Commander.Repo

      import Ecto
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Commander.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Commander.Repo, {:shared, self()})
    end

    :ok
  end
end
