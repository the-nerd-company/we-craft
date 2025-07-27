defmodule WeCraft.Env do
  @moduledoc """
  Environment variables loading and management.
  """

  @doc """
  Loads environment variables from a .env file.
  Returns :ok if successful, {:error, reason} if there's an error.

  ## Examples

      iex> WeCraft.Env.load()
      :ok

      iex> WeCraft.Env.load(".env.test")
      :ok
  """
  def load(path \\ ".env") do
    with {:ok, content} <- File.read(path),
         vars <- parse_env_file(content) do
      vars
      |> Enum.each(fn {key, value} ->
        System.put_env(key, value)
      end)

      :ok
    else
      {:error, :enoent} -> {:error, "File #{path} not found"}
      error -> error
    end
  end

  @doc """
  Loads environment variables from a .env file, raising an error if something goes wrong.

  ## Examples

      iex> WeCraft.Env.load!()
      :ok

      iex> WeCraft.Env.load!(".env.test")
      :ok
  """
  def load!(path \\ ".env") do
    case load(path) do
      :ok -> :ok
      {:error, reason} -> raise "Failed to load environment: #{reason}"
    end
  end

  @doc """
  Parses a string containing environment variables in KEY=VALUE format.
  Returns a list of {key, value} tuples.

  ## Examples

      iex> BeamBot.Env.parse_env_file("FOO=bar\\nBAZ=qux")
      [{"FOO", "bar"}, {"BAZ", "qux"}]
  """
  def parse_env_file(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Enum.map(&parse_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_line(line) do
    case String.split(line, "=", parts: 2) do
      [key, value] -> {String.trim(key), String.trim(value)}
      _ -> nil
    end
  end
end
