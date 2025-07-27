defmodule WeCraft.Repo do
  use Ecto.Repo,
    otp_app: :we_craft,
    adapter: Ecto.Adapters.Postgres
end
