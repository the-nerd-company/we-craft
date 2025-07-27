import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :we_craft, env: :test

config :waffle,
  storage: Waffle.Storage.S3,
  # or {:system, "AWS_S3_BUCKET"}
  bucket: "uploads",
  asset_host: "http://localhost:9010/uploads"

# Configure ExAws for MinIO
config :ex_aws,
  json_codec: Jason,
  # From docker-compose MINIO_ROOT_USER
  access_key_id: "AKIAIOSFODNN7EXAMPLE",
  # From docker-compose MINIO_ROOT_PASSWORD
  secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  # Default region
  region: "local",
  s3: [
    scheme: "http://",
    host: "localhost",
    # MinIO API port
    port: 9010,
    # Required for MinIO
    force_path_style: true
  ]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :we_craft, WeCraft.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "wecraft_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 5469,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :we_craft, WeCraftWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ORwuBLpkBDuFVJfIwhb4xZPaBSRnGz9P8VP4pmwLgcjAndlp1tSAGClNKk4XZ3RJ",
  server: false

# In test we don't send emails
config :we_craft, WeCraft.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :we_craft,
  email_from_name: "Account's corp",
  email_from_address: "accounts@corps.com",
  marketing_link: "http://localhost:4000",
  base_url: "http://localhost:4000",
  admin_email: "admin@wecraftapp.com"
