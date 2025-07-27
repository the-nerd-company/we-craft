alias WeCraft.Accounts.User
alias WeCraft.Profiles.Profile
alias WeCraft.Projects
alias WeCraft.Projects.{NeedsTags, TechnicalTags}
alias WeCraft.Repo

# Read tale content from file using :priv path
priv_dir = :code.priv_dir(:we_craft)

# Run MinIO setup first
Code.require_file("setup_minio.exs", __DIR__)

_admin_user =
  User.email_changeset(%User{}, %{email: "admin@wecraftapp.com"})
  |> User.name_changeset(%{name: "Admin"})
  |> User.password_changeset(%{password: "adminadminadmin"})
  |> User.confirm_changeset()
  |> Repo.insert!()

for _ <- 1..10 do
  user =
    User.email_changeset(%User{}, %{email: Faker.Internet.email()})
    |> User.name_changeset(%{name: Faker.Person.name()})
    |> User.password_changeset(%{password: "P@ssw0rdP@ssw0rd"})
    |> User.confirm_changeset()
    |> Repo.insert!()

  _profile =
    Profile.changeset(
      %Profile{},
      %{
        bio: Faker.Lorem.paragraph(3),
        skills: Enum.take_random(TechnicalTags.all_tags(), Enum.random(2..5)),
        user_id: user.id
      }
    )
    |> Repo.insert!()

  status = Enum.random([:idea, :in_dev, :live])

  {:ok, _project} =
    Projects.create_project(%{
      attrs: %{
        title: Faker.Pizza.pizza(),
        description: Faker.Lorem.paragraph(5),
        tags: Enum.take_random(TechnicalTags.all_tags(), Enum.random(2..10)),
        needs: Enum.take_random(NeedsTags.all_needs(), Enum.random(1..2)),
        repository_url: Faker.Internet.url(),
        status: status,
        visibility: :public,
        owner_id: user.id
      }
    })
end
