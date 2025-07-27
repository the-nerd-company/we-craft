defmodule WeCraft.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Configure OpenTelemetry using config-based approach instead of direct API calls

    # First setup standard OpenTelemetry
    _ = OpentelemetryBandit.setup()
    _ = OpentelemetryPhoenix.setup(adapter: :bandit)
    _ = OpentelemetryEcto.setup([:we_craft, :repo])
    _ = OpentelemetryLoggerMetadata.setup()

    # # Setup OpenTelemetry Logger Handler
    # :logger.add_handler(:otel_handler, :opentelemetry_logger, %{})
    # :logger.add_handlers(:opentelemetry)

    children = [
      WeCraftWeb.Telemetry,
      WeCraft.Repo,
      {DNSCluster, query: Application.get_env(:we_craft, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WeCraft.PubSub},
      # Start Finch for HTTP requests
      {Finch, name: WeCraft.Finch},
      # Start a worker by calling: WeCraft.Worker.start_link(arg)
      # {WeCraft.Worker, arg},
      # Start to serve requests, typically the last entry
      WeCraftWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeCraft.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WeCraftWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
