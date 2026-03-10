defmodule Astraplex.Messaging.Channel do
  @moduledoc "Channel resource for group messaging with admin-managed membership."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)

    attribute(:name, :ci_string,
      allow_nil?: false,
      public?: true,
      constraints: [max_length: 80, trim?: true]
    )

    attribute(:description, :string,
      allow_nil?: true,
      public?: true,
      constraints: [max_length: 500]
    )

    attribute(:status, :atom,
      constraints: [one_of: [:active, :archived]],
      default: :active,
      allow_nil?: false,
      public?: true
    )

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_name, [:name])
  end

  relationships do
    has_many :memberships, Astraplex.Messaging.Membership
    has_many :messages, Astraplex.Messaging.Message

    many_to_many :members, Astraplex.Accounts.User do
      through(Astraplex.Messaging.Membership)
      source_attribute_on_join_resource(:channel_id)
      destination_attribute_on_join_resource(:user_id)
    end
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:name, :description])
    end

    update :update do
      primary?(true)
      accept([:name, :description])
    end

    update :archive do
      accept([])
      change(set_attribute(:status, :archived))
    end

    read :list_for_user do
      description("List active and archived channels the current user is a member of.")
      filter(expr(status in [:active, :archived] and exists(memberships, user_id == ^actor(:id))))
      prepare(build(sort: [name: :asc]))
    end
  end

  policies do
    policy action([:create, :update, :archive]) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:read) do
      authorize_if(expr(^actor(:role) == :admin))
      authorize_if(expr(exists(memberships, user_id == ^actor(:id))))
    end

    policy action(:list_for_user) do
      authorize_if(always())
    end
  end

  postgres do
    table("channels")
    repo(Astraplex.Repo)
  end
end
