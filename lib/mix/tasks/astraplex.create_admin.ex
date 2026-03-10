defmodule Mix.Tasks.Astraplex.CreateAdmin do
  @moduledoc "Creates an admin user. Usage: mix astraplex.create_admin email password"
  @shortdoc "Create an admin user"

  use Mix.Task

  @doc "Run the create admin task with the given arguments."
  def run([email, password]) do
    Mix.Task.run("app.start")

    case Ash.Changeset.for_create(Astraplex.Accounts.User, :create_user, %{
           email: email,
           password: password,
           password_confirmation: password,
           role: :admin
         })
         |> Ash.create(authorize?: false) do
      {:ok, user} ->
        Mix.shell().info("Admin user created: #{user.email}")

      {:error, %Ash.Error.Invalid{} = error} ->
        message =
          error
          |> Ash.Error.to_ash_error()
          |> Map.get(:errors, [])
          |> Enum.map_join(", ", &Exception.message/1)

        Mix.raise("Failed to create admin: #{message}")

      {:error, error} ->
        Mix.raise("Failed to create admin: #{inspect(error)}")
    end
  end

  def run(_args) do
    Mix.raise("Usage: mix astraplex.create_admin <email> <password>")
  end
end
