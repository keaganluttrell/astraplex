defmodule Astraplex.Messaging.Membership do
  @moduledoc "Membership join resource linking users to channels."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :channel, Astraplex.Messaging.Channel, allow_nil?: false
    belongs_to :user, Astraplex.Accounts.User, allow_nil?: false
  end

  identities do
    identity(:unique_membership, [:channel_id, :user_id])
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:channel_id, :user_id])
    end
  end

  policies do
    policy action([:create, :destroy]) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:read) do
      authorize_if(expr(^actor(:role) == :admin))
      authorize_if(expr(exists(channel.memberships, user_id == ^actor(:id))))
    end
  end

  pub_sub do
    module(AstraplexWeb.Endpoint)
    prefix("membership")

    publish(:create, ["changed", :user_id])
    publish(:destroy, ["changed", :user_id])
  end

  postgres do
    table("memberships")
    repo(Astraplex.Repo)
  end
end
