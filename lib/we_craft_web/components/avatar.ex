defmodule WeCraftWeb.Components.Avatar do
  @moduledoc """
  A component for displaying user avatars in the WeCraft application.
  """
  import Phoenix.Component

  def avatar(assigns) do
    ~H"""
    <div class="avatar mr-4">
      <div class="bg-neutral rounded-full w-16 h-16 relative">
        <div class="text-xl font-bold text-neutral-content absolute inset-0 flex items-center justify-center">
          {avatar_initials(@name)}
        </div>
      </div>
    </div>
    """
  end

  def avatar_small(assigns) do
    ~H"""
    <div class="avatar mr-4">
      <div class="bg-neutral rounded-full w-10 h-10 relative">
        <div class="text-sm font-bold text-neutral-content absolute inset-0 flex items-center justify-center">
          {avatar_initials(@name)}
        </div>
      </div>
    </div>
    """
  end

  def avatar_initials(nil), do: "??"

  def avatar_initials(name) do
    name
    |> String.split(" ", trim: true)
    |> Enum.map_join("", &String.first/1)
    |> String.slice(0, 2)
    |> String.upcase()
  end
end
