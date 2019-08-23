use Mix.Config

config :commander, Commander.Repo,
  database: "commander_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :commander, ecto_repos: [Commander.Repo]
