# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Astraplex.Repo.insert!(%Astraplex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env() == :dev do
  alias Astraplex.Accounts.User

  {:ok, admin_hash} = AshAuthentication.BcryptProvider.hash("admin123!")
  {:ok, staff_hash} = AshAuthentication.BcryptProvider.hash("staff123!")

  admin =
    Ash.Seed.seed!(User, %{
      email: "admin@astraplex.dev",
      hashed_password: admin_hash,
      role: :admin,
      status: :active
    })

  IO.puts("Created admin: #{admin.email}")

  for i <- 1..5 do
    staff =
      Ash.Seed.seed!(User, %{
        email: "staff#{i}@astraplex.dev",
        hashed_password: staff_hash,
        role: :staff,
        status: :active
      })

    IO.puts("Created staff: #{staff.email}")
  end

  IO.puts("\nDev seed data created: 1 admin + 5 staff users")
  IO.puts("Admin login: admin@astraplex.dev / admin123!")
  IO.puts("Staff login: staff1@astraplex.dev / staff123!")
end
