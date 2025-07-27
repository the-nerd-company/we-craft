defmodule WeCraft.Profiles.ProfilePermissions do
  @moduledoc """
  Module to handle permissions related to user profiles.
  """
  alias WeCraft.Profiles.Profile

  def can_edit_profile?(%Profile{user_id: _user_id}, nil), do: false
  def can_edit_profile?(%Profile{user_id: user_id}, %{user: user}), do: user_id == user.id
end
