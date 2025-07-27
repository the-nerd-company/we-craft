defmodule WeCraft.Projects.Project do
  @moduledoc """
  A module representing a project in the WeCraft application.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias WeCraft.Projects.BusinessTags
  alias WeCraft.Projects.NeedsTags
  alias WeCraft.Projects.TechnicalTags

  @status_values [:idea, :in_dev, :private_beta, :public_beta, :live]
  @visibility_values [:public]

  def all_statuses, do: @status_values

  # Helper functions for status display
  def status_display(:idea), do: "Idea"
  def status_display(:in_dev), do: "In Dev"
  def status_display(:private_beta), do: "Private β"
  def status_display(:public_beta), do: "Public β"
  def status_display(:live), do: "Live"

  def status_display(status) when is_atom(status),
    do: status |> Atom.to_string() |> String.capitalize()

  def status_display(status), do: status

  def all_visibility, do: @visibility_values

  schema "projects" do
    field :title, :string
    field :description, :string
    field :repository_url, :string
    field :tags, {:array, :string}, default: []
    field :needs, {:array, :string}, default: []
    field :business_domains, {:array, :string}, default: []
    field :status, Ecto.Enum, values: @status_values, default: :idea
    field :visibility, Ecto.Enum, values: @visibility_values, default: :public
    field :followers_count, :integer, virtual: true, default: 0

    belongs_to :owner, WeCraft.Accounts.User
    many_to_many :followers, WeCraft.Accounts.User, join_through: WeCraft.Projects.Follower

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :title,
      :repository_url,
      :description,
      :tags,
      :needs,
      :business_domains,
      :status,
      :visibility,
      :owner_id
    ])
    |> validate_required([:title, :description, :status, :visibility])
    |> validate_tags()
    |> validate_needs()
    |> validate_business_domains()
  end

  defp validate_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags ->
        # Convert tags to lowercase for consistency
        normalized_tags = Enum.map(tags, &String.downcase/1)

        # Get invalid tags
        invalid_tags =
          Enum.filter(normalized_tags, fn tag -> tag not in TechnicalTags.all_tags() end)

        case invalid_tags do
          [] ->
            # All tags are valid, update with normalized tags
            put_change(changeset, :tags, normalized_tags)

          _ ->
            # Some tags are invalid
            add_error(
              changeset,
              :tags,
              "contains invalid technical tags: #{Enum.join(invalid_tags, ", ")}"
            )
        end
    end
  end

  defp validate_needs(changeset) do
    case get_change(changeset, :needs) do
      nil ->
        changeset

      needs ->
        # Convert needs to lowercase for consistency
        normalized_needs = Enum.map(needs, &String.downcase/1)

        # Get invalid needs
        invalid_needs =
          Enum.filter(normalized_needs, fn need -> need not in NeedsTags.all_needs() end)

        case invalid_needs do
          [] ->
            # All needs are valid, update with normalized needs
            put_change(changeset, :needs, normalized_needs)

          _ ->
            # Some needs are invalid
            add_error(
              changeset,
              :needs,
              "contains invalid needs: #{Enum.join(invalid_needs, ", ")}"
            )
        end
    end
  end

  defp validate_business_domains(changeset) do
    case get_change(changeset, :business_domains) do
      nil ->
        changeset

      domains ->
        # Convert domains to lowercase for consistency
        normalized_domains = Enum.map(domains, &String.downcase/1)

        # Get invalid domains
        invalid_domains =
          Enum.filter(normalized_domains, fn domain -> domain not in BusinessTags.all_tags() end)

        case invalid_domains do
          [] ->
            # All domains are valid, update with normalized domains
            put_change(changeset, :business_domains, normalized_domains)

          _ ->
            # Some domains are invalid
            add_error(
              changeset,
              :business_domains,
              "contains invalid business domains: #{Enum.join(invalid_domains, ", ")}"
            )
        end
    end
  end
end
