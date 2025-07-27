defmodule WeCraftWeb.HealthControllerTest do
  @moduledoc """
  Test module for HealthController
  """
  use WeCraftWeb.ConnCase, async: true

  describe "GET /health" do
    test "returns ok status", %{conn: conn} do
      conn = get(conn, "/health")

      assert json_response(conn, 200) == %{"status" => "ok"}
    end
  end
end
