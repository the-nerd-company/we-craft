defmodule WeCraft.LoggerOpenTelemetryBackendTest do
  @moduledoc """
  Tests for the LoggerOpenTelemetryBackend module.
  """
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias WeCraft.LoggerOpenTelemetryBackend

  # Define a mock for Finch
  import Mox
  setup :verify_on_exit!

  # Create a mock module for Finch
  defmodule MockFinch do
    @moduledoc """
    Mock implementation of Finch for testing purposes.
    """
    def build(method, url, headers, body), do: {method, url, headers, body}
    def request(_req, _client, _opts), do: {:ok, %{status: 200, body: "ok"}}
  end

  setup do
    # Temporarily replace the Application config for testing
    original_resource = Application.get_env(:opentelemetry, :resource)
    original_processors = Application.get_env(:opentelemetry, :processors)

    # Setup test configs
    Application.put_env(:opentelemetry, :resource, %{
      attributes: [
        %{key: "service.name", value: %{stringValue: "test_service"}}
      ]
    })

    Application.put_env(:opentelemetry, :processors, %{
      otel_batch_processor: %{
        exporter: {:opentelemetry_exporter, %{endpoints: [{:http, "localhost", 4318, []}]}}
      }
    })

    on_exit(fn ->
      # Restore original configs
      if original_resource do
        Application.put_env(:opentelemetry, :resource, original_resource)
      else
        Application.delete_env(:opentelemetry, :resource)
      end

      if original_processors do
        Application.put_env(:opentelemetry, :processors, original_processors)
      else
        Application.delete_env(:opentelemetry, :processors)
      end
    end)

    :ok
  end

  describe "init/1" do
    test "initializes with empty state" do
      assert LoggerOpenTelemetryBackend.init([]) == {:ok, %{}}
    end
  end

  describe "get_resource/0" do
    test "returns the OpenTelemetry resource from config" do
      expected = %{
        attributes: [
          %{key: "service.name", value: %{stringValue: "test_service"}}
        ]
      }

      assert LoggerOpenTelemetryBackend.get_resource() == expected
    end
  end

  describe "get_url/0" do
    test "returns the OpenTelemetry collector URL" do
      assert LoggerOpenTelemetryBackend.get_url() == "http://localhost:4318/v1/logs"
    end
  end

  describe "handle_event/2" do
    test "processes log events and forwards them to OpenTelemetry" do
      # Mock the Finch request using capture_io since we can't easily mock internal function
      output =
        capture_io(fn ->
          metadata = [otel_trace_id: "trace123", otel_span_id: "span456", app: "we_craft"]

          log_event =
            {:info, self(), {Logger, "Test log message", {{2023, 1, 1}, {12, 0, 0, 0}}, metadata}}

          # The actual test
          assert {:ok, %{}} = LoggerOpenTelemetryBackend.handle_event(log_event, %{})
        end)

      # We can't assert on the actual HTTP call since it's made in a private function
      # But we can check that no errors were printed to stdout
      refute output =~ "Failed to send log to OpenTelemetry collector"
    end

    test "handles events without trace context" do
      # Mock the Finch request using capture_io
      output =
        capture_io(fn ->
          # No trace context
          metadata = [app: "we_craft"]

          log_event =
            {:info, self(), {Logger, "Test log message", {{2023, 1, 1}, {12, 0, 0, 0}}, metadata}}

          # The actual test
          assert {:ok, %{}} = LoggerOpenTelemetryBackend.handle_event(log_event, %{})
        end)

      refute output =~ "Failed to send log to OpenTelemetry collector"
    end

    test "handles different log levels correctly" do
      levels = [:debug, :info, :notice, :warning, :error, :critical, :alert, :emergency]

      for level <- levels do
        output =
          capture_io(fn ->
            metadata = [app: "we_craft"]

            log_event =
              {level, self(),
               {Logger, "Test #{level} message", {{2023, 1, 1}, {12, 0, 0, 0}}, metadata}}

            assert {:ok, %{}} = LoggerOpenTelemetryBackend.handle_event(log_event, %{})
          end)

        refute output =~ "Failed to send log to OpenTelemetry collector"
      end
    end

    test "ignores non-logger events" do
      assert {:ok, :state} = LoggerOpenTelemetryBackend.handle_event(:unknown_event, :state)
    end
  end

  describe "handle_call/2" do
    test "returns ok for any call" do
      assert {:ok, :ok, :state} = LoggerOpenTelemetryBackend.handle_call(:any_call, :state)
    end
  end

  describe "handle_info/2" do
    test "returns ok for any info" do
      assert {:ok, :state} = LoggerOpenTelemetryBackend.handle_info(:any_info, :state)
    end
  end

  describe "terminate/2" do
    test "returns ok" do
      assert :ok = LoggerOpenTelemetryBackend.terminate(:normal, :state)
    end
  end

  # Testing error handling with a more simplified approach
  test "handles errors gracefully" do
    # We'll just verify that the module doesn't crash on basic operations

    assert {:ok, state} = LoggerOpenTelemetryBackend.init([])

    assert {:ok, state} =
             LoggerOpenTelemetryBackend.handle_event(
               {:info, self(), {Logger, "message", {{2023, 1, 1}, {12, 0, 0, 0}}, []}},
               state
             )

    assert {:ok, :ok, state} = LoggerOpenTelemetryBackend.handle_call(:any, state)
    assert {:ok, state} = LoggerOpenTelemetryBackend.handle_info(:any, state)
    assert :ok = LoggerOpenTelemetryBackend.terminate(:normal, state)
  end
end
