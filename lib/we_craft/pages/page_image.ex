defmodule WeCraft.Pages.PageImage do
  @moduledoc """
  Handles image uploads and processing for page images.
  """
  use Waffle.Definition

  @versions [:original, :thumb]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  def acl(:thumb, _), do: :public_read

  def get_extension(%{filename: file_name}) do
    get_extension(file_name)
  end

  def get_extension(%{file_name: file_name}) do
    get_extension(file_name)
  end

  def get_extension(name) do
    name |> Path.extname() |> String.downcase()
  end

  def validate({file, _}) do
    file_extension = get_extension(file.file_name)
    Enum.member?(@extension_whitelist, file_extension)
  end

  def transform(:thumb, _) do
    {:convert, "-thumbnail 100x100^ -gravity center -extent 100x100 -format png", :png}
  end

  def filename(version, {_file, %{page_id: _page_id, uuid: uuid, project_id: _project_id}}) do
    "#{version}_#{uuid}"
  end

  def storage_dir(_, {_file, %{page_id: page_id, uuid: _uuid, project_id: project_id}}) do
    "projects/#{project_id}/pages/#{page_id}/images/"
  end

  def default_url(:thumb) do
    "https://placehold.it/100x100"
  end
end
