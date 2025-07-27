import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/we_craft start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :we_craft, WeCraftWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :we_craft,
    env: :prod,
    jitsi_domain: System.get_env("JITSI_DOMAIN")

  bucket_name = System.get_env("BUCKET_NAME")

  config :waffle,
    storage: Waffle.Storage.S3,
    # or {:system, "AWS_S3_BUCKET"}
    bucket: bucket_name,
    asset_host:
      "http://#{System.get_env("MINIO_HOST")}:#{System.get_env("MINIO_PORT")}/#{bucket_name}"

  config :ex_aws,
    json_codec: Jason,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    # Default region
    region: System.get_env("AWS_REGION"),
    s3: [
      scheme: "http://",
      host: System.get_env("MINIO_HOST"),
      port: System.get_env("MINIO_PORT") |> String.to_integer(),
      force_path_style: true
    ]

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :we_craft, WeCraft.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :we_craft, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :we_craft, WeCraftWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :we_craft, WeCraft.Mailer,
    adapter: Swoosh.Adapters.AmazonSES,
    region: System.get_env("AWS_REGION"),
    access_key: System.get_env("AWS_API_KEY"),
    secret: System.get_env("AWS_API_SECRET")

  config :we_craft,
    email_from_name: System.get_env("EMAIL_FROM_NAME"),
    email_from_address: System.get_env("EMAIL_FROM_ADDRESS"),
    admin_email: System.get_env("ADMIN_EMAIL"),
    marketing_link: "https://www.wecraftapp.com",
    base_url: "https://www.wecraftapp.com"

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :we_craft, WeCraftWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :we_craft, WeCraftWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :we_craft, WeCraft.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :logger,
    backends: [:console, WeCraft.LoggerOpenTelemetryBackend],
    level: :info

  # Enable OpenTelemetry SDK - using stdout for now as OpenObserve doesn't directly support OTLP
  # We'll rely on our direct logging module for OpenObserve integration
  config :opentelemetry,
    resource: %{
      # Add service identification attributes
      "service.name": "web",
      "service.namespace": "wecraft_production",
      "deployment.environment": "production"
    },
    processors: [
      {:otel_batch_processor,
       %{
         # Using stdout exporter for debugging purposes
         exporter: {
           :opentelemetry_exporter,
           %{endpoints: [{:http, "otel-collector", 4318, []}]}
         }
       }}
    ]
end
