defmodule WeCraftWeb.TestTelemetryController do
  @moduledoc """
  Controller for testing OpenTelemetry spans and logging
  This controller provides an endpoint to create test spans and log events
  to verify telemetry integration.
  """
  use WeCraftWeb, :controller
  require OpenTelemetry.Tracer
  require Logger

  def test(conn, params) do
    Logger.info("Starting telemetry test span")

    # Get OpenTelemetry tracer configuration
    tracer_config = :opentelemetry.get_tracer(:wecraft_tracer)
    Logger.info("Tracer config: #{inspect(tracer_config)}")

    Logger.error("Trying error logging for telemetry")

    # Create a test span to verify telemetry is working
    _ =
      OpenTelemetry.Tracer.with_span "wecraft.test" do
        # Add some attributes to the span
        OpenTelemetry.Tracer.set_attributes([
          {"test.attribute", "test_value"},
          {"test.timestamp", DateTime.utc_now() |> DateTime.to_string()}
        ])

        Logger.info("Added attributes to span")

        # Simulate some work
        :timer.sleep(100)

        # Log an event within the span
        OpenTelemetry.Tracer.add_event("test.event", [
          {"event.detail", "This is a test event"}
        ])

        Logger.info("Added event to span")
      end

    Logger.info("Completed telemetry test span")

    # Test a database query if requested
    test_db = Map.get(params, "db", "false") == "true"

    db_result =
      if test_db do
        Logger.info("Testing database query for telemetry")
        {:ok, result} = WeCraft.Repo.query("SELECT 1 as test")
        %{rows: result.rows, num_rows: result.num_rows}
      else
        nil
      end

    # Test an error if requested
    test_error = Map.get(params, "error", "false") == "true"

    if test_error do
      Logger.info("Testing error for telemetry")

      # Also test an exception that will be captured by telemetry
      raise "Test error for telemetry capturing"
    end

    json(conn, %{
      message: "Telemetry test span sent",
      timestamp: DateTime.utc_now() |> DateTime.to_string(),
      db_result: db_result
    })
  end
end
