defmodule WeCraft.Profiles.Profile do
  @moduledoc """
  A module representing a user profile in the WeCraft application.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias WeCraft.Projects.NeedsTags
  alias WeCraft.Projects.TechnicalTags

  schema "profiles" do
    field :bio, :string
    field :skills, {:array, :string}, default: []
    field :offers, {:array, :string}, default: []

    belongs_to :user, WeCraft.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :skills, :offers, :user_id])
    |> validate_required([:bio, :user_id])
    |> validate_skills()
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def update_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :skills, :offers])
    |> validate_required([:bio])
    |> validate_skills()
    |> validate_offers()
  end

  defp validate_skills(changeset) do
    case get_change(changeset, :skills) do
      nil ->
        changeset

      skills ->
        # Convert skills to lowercase for consistency
        normalized_skills = Enum.map(skills, &String.downcase/1)

        # Get invalid skills
        invalid_skills =
          Enum.filter(normalized_skills, fn skill -> skill not in TechnicalTags.all_tags() end)

        case invalid_skills do
          [] ->
            # All skills are valid, update with normalized skills
            put_change(changeset, :skills, normalized_skills)

          _ ->
            # Some skills are invalid
            add_error(
              changeset,
              :skills,
              "contains invalid skills: #{Enum.join(invalid_skills, ", ")}"
            )
        end
    end
  end

  defp validate_offers(changeset) do
    case get_change(changeset, :offers) do
      nil ->
        changeset

      offers ->
        # Convert offers to lowercase for consistency
        normalized_offers = Enum.map(offers, &String.downcase/1)

        # Get invalid offers
        invalid_offers =
          Enum.filter(normalized_offers, fn offer -> offer not in NeedsTags.all_needs() end)

        case invalid_offers do
          [] ->
            # All offers are valid, update with normalized offers
            put_change(changeset, :offers, normalized_offers)

          _ ->
            # Some offers are invalid
            add_error(
              changeset,
              :offers,
              "contains invalid offers: #{Enum.join(invalid_offers, ", ")}"
            )
        end
    end
  end
end
