defmodule WeCraft.LoggerOpenTelemetryBackend do
  @moduledoc """
  Custom Logger backend to export logs to OpenTelemetry.
  This backend captures log events and sends them to an OpenTelemetry collector.

  https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/file-exporter.md
  """
  @behaviour :gen_event

  def init(_opts) do
    {:ok, %{}}
  end

  def get_resource do
    # Get the OpenTelemetry collector endpoint from the config
    Application.get_env(:opentelemetry, :resource)
  end

  def get_url do
    {:opentelemetry_exporter, %{endpoints: [{:http, endpoint, port, []}]}} =
      Application.get_env(:opentelemetry, :processors)[:otel_batch_processor][:exporter]

    "http://#{endpoint}:#{port}/v1/logs"
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    # First check if trace context exists in metadata

    trace_id = Keyword.get(md, :otel_trace_id) |> to_string()
    span_id = Keyword.get(md, :otel_span_id) |> to_string()

    # Use metadata if available, otherwise use current span context
    export_log(level, msg, ts, md, trace_id, span_id)

    {:ok, state}
  end

  def handle_event(_, state), do: {:ok, state}

  def handle_call(_, state), do: {:ok, :ok, state}
  def handle_info(_, state), do: {:ok, state}
  def terminate(_, _), do: :ok

  defp export_log(level, msg, ts, md, trace_id, span_id) do
    # Convert timestamp to nanoseconds since Unix epoch
    # Logger.metadata timestamps are in local timezone, converting to UTC
    ns_timestamp = timestamp_to_unix_nano(ts)

    # Convert metadata to OTLP attributes format
    formatted_attributes = format_attributes(md)

    # Build log record according to OTLP spec
    {severity_number, severity_text} = severity_number_for_level(level)

    log_record = %{
      # String format as in example
      timeUnixNano: "#{ns_timestamp}",
      severityNumber: severity_number,
      severityText: severity_text,
      body: %{
        stringValue: to_string(msg)
      },
      traceId: trace_id,
      spanId: span_id,
      attributes:
        formatted_attributes
        |> Enum.filter(fn %{key: key} ->
          key not in ["otel_span_id", "otel_trace_id", "otel_trace_flags", "erl_level"]
        end)
    }

    send_otlp_http(log_record)
  end

  # Format metadata as OTLP attributes (array of key-value pairs with proper types)
  defp format_attributes(md) do
    Enum.map(md, fn {key, value} ->
      %{
        key: to_string(key),
        value: format_attribute_value(value)
      }
    end)
  end

  # Format attribute values according to their type
  defp format_attribute_value(value) when is_binary(value), do: %{stringValue: value}
  defp format_attribute_value(value) when is_integer(value), do: %{intValue: "#{value}"}
  defp format_attribute_value(value) when is_float(value), do: %{doubleValue: value}
  defp format_attribute_value(value) when is_boolean(value), do: %{boolValue: value}
  defp format_attribute_value(nil), do: %{stringValue: ""}
  defp format_attribute_value(value), do: %{stringValue: inspect(value)}

  # Map Elixir log levels to OpenTelemetry severity numbers
  # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/logs/data-model.md#severity-fields
  defp severity_number_for_level(:debug), do: {5, "DEBUG"}
  defp severity_number_for_level(:info), do: {9, "INFO"}
  defp severity_number_for_level(:notice), do: {10, "NOTICE"}
  defp severity_number_for_level(:warning), do: {13, "WARN"}
  defp severity_number_for_level(:error), do: {17, "ERROR"}
  defp severity_number_for_level(:critical), do: {18, "CRITICAL"}
  defp severity_number_for_level(:alert), do: {21, "FATAL"}
  defp severity_number_for_level(:emergency), do: {24, "EMERGENCY"}
  defp severity_number_for_level(_), do: {0, "UNSPECIFIED"}

  defp timestamp_to_unix_nano(_ts) do
    # Instead of parsing the Logger timestamp which is in local timezone and lacks precision,
    # use the current system time in nanoseconds which is already in UTC and has better precision
    System.system_time(:nanosecond)
  end

  defp send_otlp_http(log_record) do
    # Format payload according to OpenTelemetry protocol format
    payload =
      Jason.encode!(%{
        resourceLogs: [
          %{
            resource: get_resource(),
            scopeLogs: [
              %{
                scope: %{},
                logRecords: [log_record]
              }
            ]
          }
        ]
      })

    headers = [
      {"content-type", "application/json"}
    ]

    # Use try/rescue to ensure logger doesn't crash the application
    try do
      Finch.build(:post, get_url(), headers, payload)
      |> Finch.request(WeCraft.Finch, receive_timeout: 5000)
    rescue
      e ->
        # Just log the error but don't crash
        IO.puts("Failed to send log to OpenTelemetry collector: #{inspect(e)}")
        {:error, :send_failed}
    catch
      _, reason ->
        IO.puts("Failed to send log to OpenTelemetry collector: #{inspect(reason)}")
        {:error, :send_failed}
    end
  end
end
