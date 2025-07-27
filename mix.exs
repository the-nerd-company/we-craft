defmodule WeCraft.MixProject do
  @moduledoc """
  Mix project configuration for the WeCraft application.
  This module defines the project's metadata, dependencies, and application settings.
  """
  use Mix.Project

  def project do
    [
      app: :we_craft,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      releases: [
        we_craft: [
          applications: [opentelemetry_exporter: :permanent, opentelemetry: :temporary]
        ]
      ],
      test_coverage: [
        tool: ExCoveralls,
        output_dir: "cover/",
        preferred_cli_env: [
          coveralls: :test,
          "coveralls.detail": :test,
          "coveralls.post": :test,
          "coveralls.html": :test,
          "coveralls.cobertura": :test
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [
          :mix,
          :ex_unit,
          :plug,
          :ecto,
          :phoenix,
          :phoenix_pubsub,
          :phoenix_template,
          :eex,
          # :ex_cldr,
          # :ex_cldr_numbers,
          # :ex_cldr_dates_times,
          # :ex_cldr_calendars,
          # :ex_cldr_currencies,
          # :opentelemetry_api,
          :opentelemetry,
          :opentelemetry_exporter
        ],
        plt_core_path: "priv/plts/core.plt",
        plt_add_deps: :apps_direct,
        plt_ignore_apps: [:ffmpex],
        flags: [:unmatched_returns, :error_handling, :no_opaque]
      ],
      # License and package information
      licenses: ["Custom Non-Commercial"],
      description:
        "WeCraft - Phoenix LiveView SaaS Platform (Open Source, Non-Commercial License)"
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {WeCraft.Application, []},
      extra_applications: [:logger, :runtime_tools, :tls_certificate_check, :inets]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0-rc.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:mailex, git: "https://github.com/luphex/mailex.git", ref: "main"},
      {:gen_smtp, "~> 1.3"},
      {:slugify, "~> 1.3"},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.12"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:uuid, "~> 1.1"},
      # Quality of life
      {:faker, "~> 0.19.0-alpha.1", only: [:dev, :test]},
      {:git_hooks, "~> 0.8.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.2"},
      {:tidewave, "~> 0.1", only: [:dev]},
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_exporter, "~> 1.8"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_logger_metadata, "~> 0.2.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_bandit, "~> 0.2"},
      {:logger_json, "~> 5.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind we_craft", "esbuild we_craft"],
      "assets.deploy": [
        "tailwind we_craft --minify",
        "esbuild we_craft --minify",
        "phx.digest"
      ]
    ]
  end
end
