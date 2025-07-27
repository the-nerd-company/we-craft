defmodule WeCraftWeb.Api.V1.Pages.FileController do
  @moduledoc """
  Controller for handling file uploads for pages.
  """
  use WeCraftWeb, :controller

  alias WeCraft.Pages
  alias WeCraft.Pages.PageImage

  require Logger

  def create(conn, %{"page_id" => page_id, "image" => image}) do
    {:ok, page} = Pages.get_page(%{page_id: page_id, scope: conn.assigns.current_scope})
    uuid = UUID.uuid4()

    scope = %{project_id: page.project_id, uuid: uuid, page_id: page.id}

    extension = PageImage.get_extension(image)

    case PageImage.store({image, scope}) do
      {:ok, _name} ->
        json(
          conn,
          %{
            "success" => 1,
            "file" => %{
              "url" =>
                "/api/v1/pages/#{page.id}/files/#{PageImage.filename(:original, {image, scope})}#{extension}"
            }
          }
        )

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => reason})
    end
  end

  def show(conn, %{"page_id" => page_id, "file_name" => file_name}) do
    {:ok, page} = Pages.get_page(%{page_id: page_id, scope: conn.assigns.current_scope})

    [uuid | _] = String.split(file_name, ".")
    uuid = String.replace(uuid, "original_", "")
    scope = %{uuid: uuid, page_id: page.id, project_id: page.project_id}
    url = PageImage.url({file_name, scope}, :original)

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body, headers: headers}} ->
        content_type =
          (Map.get(headers, "content-type") || ["application/octet-stream"]) |> List.first()

        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, body)

      _ ->
        Logger.error("File not found: #{file_name} for page #{page_id} with url: #{url}")

        conn
        |> put_status(:not_found)
        |> json(%{"error" => "File not found"})
    end
  end
end
