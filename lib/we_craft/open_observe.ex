defmodule WeCraft.OpenObserve do
  @moduledoc """
  Utility module for sending logs directly to OpenObserve
  """

  require Logger

  @credentials Application.compile_env(:we_craft, :open_observe_credentials, %{
                 username: "guillaume.bailleul@gmail.com",
                 password: "TmPmjxAz8bJ6ieSp"
               })

  @doc """
  Send a log entry to OpenObserve
  """
  def send_log(level, message, metadata \\ %{}) do
    username = @credentials[:username]
    password = @credentials[:password]
    endpoint = "https://openobserve.thenerdcompany.us/api/default/default/_json"

    payload =
      Jason.encode!([
        %{
          level: Atom.to_string(level),
          log: message,
          service: "wecraft",
          timestamp: DateTime.utc_now() |> DateTime.to_string(),
          metadata: metadata
        }
      ])

    headers = [
      {~c"Content-Type", ~c"application/json"},
      {~c"Authorization", ~c"Basic " ++ :base64.encode_to_string("#{username}:#{password}")}
    ]

    case :httpc.request(
           :post,
           {String.to_charlist(endpoint), headers, ~c"application/json", payload},
           [],
           []
         ) do
      {:ok, {{_, 200, _}, _, _}} ->
        Logger.info("Successfully sent log to OpenObserve: #{message}")
        :ok

      error ->
        Logger.error("Failed to send log to OpenObserve: #{inspect(error)}")
        {:error, error}
    end
  end
end
