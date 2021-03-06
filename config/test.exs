use Mix.Config

# Configure your database
config :curbside_concerts, CurbsideConcerts.Repo,
  username: "postgres",
  password: "postgres",
  database: "curbside_concerts_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :curbside_concerts_web, CurbsideConcertsWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :curbside_concerts_web, CurbsideConcertsWeb.Mailer,
  adapter: Bamboo.TestAdapter
