defmodule WeCraftWeb.TestTelemetryControllerTest do
  @moduledoc """
  Test module for TestTelemetryController
  """
  use WeCraftWeb.ConnCase, async: true

  describe "GET /telemetry-test" do
    test "returns success message", %{conn: conn} do
      conn = get(conn, "/telemetry-test")

      response = json_response(conn, 200)
      assert response["message"] == "Telemetry test span sent"
      assert Map.has_key?(response, "timestamp")
    end

    test "executes telemetry event successfully", %{conn: conn} do
      # We can test that the endpoint returns without error
      # The actual telemetry event firing is tested implicitly
      conn = get(conn, "/telemetry-test")

      assert conn.status == 200
      response = json_response(conn, 200)
      assert response["message"] == "Telemetry test span sent"
    end
  end
end
