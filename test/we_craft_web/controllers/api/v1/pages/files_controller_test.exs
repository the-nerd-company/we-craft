defmodule WeCraftWeb.Api.V1.Pages.FileControllerTest do
  use WeCraftWeb.ConnCase, async: true

  import WeCraft.ProjectsFixtures
  import WeCraft.PagesFixtures
  import WeCraftWeb.ConnCase, only: [register_and_log_in_user: 1]

  @moduledoc """
  Tests for file upload and retrieval endpoints in FileController.
  """

  setup [:register_and_log_in_user]

  setup %{conn: conn, user: user} do
    project = project_fixture(%{owner: user})
    page = page_fixture(%{project: project})
    # fetch_current_scope_for_user plug will set current_scope based on session token
    {:ok, %{conn: conn, user: user, project: project, page: page}}
  end

  describe "POST /api/v1/pages/:page_id/files" do
    test "returns success JSON on valid image", %{conn: conn, page: page} do
      upload = %Plug.Upload{
        filename: "test.jpg",
        path: sample_image_path(),
        content_type: "image/jpeg"
      }

      conn =
        post(conn, "/api/v1/pages/#{page.id}/files", %{
          "page_id" => page.id,
          "image" => upload
        })

      assert %{"success" => 1, "file" => %{"url" => url}} = json_response(conn, 200)
      assert String.contains?(url, "/api/v1/pages/#{page.id}/files/original_")
      assert String.ends_with?(url, ".jpg")
    end
  end

  describe "GET /api/v1/pages/:page_id/files/:file_name" do
    test "returns 404 for missing file", %{conn: conn, page: page} do
      conn = get(conn, "/api/v1/pages/#{page.id}/files/original_missing.png")
      assert %{"error" => "File not found"} = json_response(conn, 404)
    end
  end

  # Helpers
  defp sample_image_path do
    Path.join([File.cwd!(), "priv", "tests", "images", "sample.jpg"])
  end
end
