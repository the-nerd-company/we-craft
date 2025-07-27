defmodule WeCraft.Projects.BusinessTags do
  @moduledoc """
  Defines and manages business tags for projects.
  """

  @doc """
  Returns a list of all valid business domain tags.
  """
  def all_tags do
    [
      # Business Models
      "saas",
      "marketplace",
      "subscription",
      "freemium",
      "open_source",
      "b2b",
      "b2c",
      "b2b2c",
      "enterprise",
      "e-commerce",

      # Industry Sectors
      "fintech",
      "healthtech",
      "edtech",
      "proptech",
      "legaltech",
      "insurtech",
      "hr_tech",
      "agritech",
      "biotech",
      "cleantech",
      "retailtech",
      "traveltech",
      "foodtech",
      "govtech",

      # Application Areas
      "productivity",
      "analytics",
      "communication",
      "collaboration",
      "automation",
      "security",
      "ai",
      "machine_learning",
      "iot",
      "blockchain",
      "crypto",
      "media",
      "social",
      "gaming",
      "entertainment",
      "remote_work",

      # Target Users
      "developers",
      "designers",
      "startups",
      "small_business",
      "enterprise_business",
      "consumers",
      "students",
      "researchers",
      "creators",
      "marketers"
    ]
  end

  @doc """
  Returns a map of business tags grouped by category.
  Useful for UI organization and filtering.
  """
  def categorized_tags do
    %{
      "Business Models" => [
        "saas",
        "marketplace",
        "subscription",
        "freemium",
        "open_source",
        "b2b",
        "b2c",
        "b2b2c",
        "enterprise",
        "e-commerce"
      ],
      "Industry Sectors" => [
        "fintech",
        "healthtech",
        "edtech",
        "proptech",
        "legaltech",
        "insurtech",
        "hr_tech",
        "agritech",
        "biotech",
        "cleantech",
        "retailtech",
        "traveltech",
        "foodtech",
        "govtech"
      ],
      "Application Areas" => [
        "productivity",
        "analytics",
        "communication",
        "collaboration",
        "automation",
        "security",
        "ai",
        "machine_learning",
        "iot",
        "blockchain",
        "crypto",
        "media",
        "social",
        "gaming",
        "entertainment",
        "remote_work"
      ],
      "Target Users" => [
        "developers",
        "designers",
        "startups",
        "small_business",
        "enterprise_business",
        "consumers",
        "students",
        "researchers",
        "creators",
        "marketers"
      ]
    }
  end
end
