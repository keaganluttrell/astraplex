defmodule Astraplex.Messaging.Message do
  @moduledoc "Message resource for channel messaging with sender tracking."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)

    attribute(:body, :string,
      allow_nil?: false,
      public?: true
    )

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :channel, Astraplex.Messaging.Channel, allow_nil?: true, public?: true
    belongs_to :sender, Astraplex.Accounts.User, allow_nil?: false
  end

  actions do
    defaults([:read])

    create :send_message do
      accept([:body, :channel_id])
      change(relate_actor(:sender))
      validate(present(:channel_id))
    end
  end

  policies do
    policy action(:send_message) do
      authorize_if(Astraplex.Messaging.Checks.CanSendToChannel)
    end

    policy action(:read) do
      authorize_if(expr(^actor(:role) == :admin))
      authorize_if(expr(exists(channel.memberships, user_id == ^actor(:id))))
    end
  end

  pub_sub do
    module(AstraplexWeb.Endpoint)
    prefix("channel")

    publish(:send_message, ["messages", :channel_id])
  end

  postgres do
    table("messages")
    repo(Astraplex.Repo)
  end
end
