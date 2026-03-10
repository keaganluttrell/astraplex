defmodule Astraplex.Accounts.User do
  @moduledoc "User resource with AshAuthentication for email/password login and admin user management."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Accounts

  attributes do
    uuid_primary_key(:id)

    attribute(:email, :ci_string, allow_nil?: false, public?: true)
    attribute(:hashed_password, :string, allow_nil?: false, sensitive?: true)

    attribute(:role, :atom,
      constraints: [one_of: [:admin, :staff]],
      default: :staff,
      allow_nil?: false,
      public?: true
    )

    attribute(:status, :atom,
      constraints: [one_of: [:active, :deactivated]],
      default: :active,
      allow_nil?: false,
      public?: true
    )

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  authentication do
    tokens do
      enabled?(true)
      token_resource(Astraplex.Accounts.Token)
      require_token_presence_for_authentication?(true)

      signing_secret(fn _, _ ->
        Application.fetch_env(:astraplex, :token_signing_secret)
      end)
    end

    strategies do
      password :password do
        identity_field(:email)
        hashed_password_field(:hashed_password)
        confirmation_required?(false)
        registration_enabled?(false)
      end
    end
  end

  identities do
    identity(:unique_email, [:email])
  end

  actions do
    defaults([:read])

    read :sign_in_with_password do
      description("Sign in with email and password. Only active users can sign in.")
      get?(true)

      argument(:email, :ci_string, allow_nil?: false)
      argument(:password, :string, allow_nil?: false, sensitive?: true)

      prepare(Astraplex.Accounts.User.Preparations.ValidateActiveStatus)
      prepare(AshAuthentication.Strategy.Password.SignInPreparation)

      metadata(:token, :string, allow_nil?: false)
    end

    create :create_user do
      accept([:email, :role])

      argument(:password, :string, allow_nil?: false, sensitive?: true)
      argument(:password_confirmation, :string, allow_nil?: false, sensitive?: true)

      validate(confirm(:password, :password_confirmation))

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :password) do
          nil ->
            changeset

          password ->
            {:ok, hashed} = AshAuthentication.BcryptProvider.hash(password)
            Ash.Changeset.force_change_attribute(changeset, :hashed_password, hashed)
        end
      end)
    end

    update :update_role do
      accept([:role])
    end

    update :deactivate do
      accept([])
      change(set_attribute(:status, :deactivated))
    end

    update :reactivate do
      accept([])
      change(set_attribute(:status, :active))
    end

    read :get_by_email do
      get_by([:email])
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end

    policy action(:create_user) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:update_role) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:deactivate) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:reactivate) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:read) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:get_by_email) do
      authorize_if(expr(^actor(:role) == :admin))
    end
  end

  postgres do
    table("users")
    repo(Astraplex.Repo)
  end
end
