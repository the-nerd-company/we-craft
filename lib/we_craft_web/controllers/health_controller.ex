defmodule WeCraftWeb.HealthController do
  use WeCraftWeb, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
