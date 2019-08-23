defmodule Commander.Repo do
  use Ecto.Repo,
    otp_app: :commander,
    adapter: Ecto.Adapters.Postgres
end
