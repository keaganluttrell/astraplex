defmodule Astraplex.Messaging.Message do
  @moduledoc "Message resource for channel and conversation messaging with sender tracking."

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
    belongs_to :conversation, Astraplex.Messaging.Conversation, allow_nil?: true, public?: true
    belongs_to :sender, Astraplex.Accounts.User, allow_nil?: false
  end

  actions do
    defaults([:read])

    create :send_message do
      accept([:body, :channel_id])
      change(relate_actor(:sender))
      validate(present(:channel_id))
    end

    create :send_conversation_message do
      accept([:body, :conversation_id])
      change(relate_actor(:sender))
      validate(present(:conversation_id))
    end
  end

  policies do
    policy action(:send_message) do
      authorize_if(Astraplex.Messaging.Checks.CanSendToChannel)
    end

    policy action(:send_conversation_message) do
      authorize_if(Astraplex.Messaging.Checks.CanSendToConversation)
    end

    policy action(:read) do
      authorize_if(expr(^actor(:role) == :admin and not is_nil(channel_id)))
      authorize_if(expr(exists(channel.memberships, user_id == ^actor(:id))))
      authorize_if(expr(exists(conversation.conversation_memberships, user_id == ^actor(:id))))
    end
  end

  pub_sub do
    module(AstraplexWeb.Endpoint)
    prefix("channel")

    publish(:send_message, ["messages", :channel_id])
  end

  changes do
    change(
      fn changeset, _context ->
        Ash.Changeset.after_action(changeset, fn _changeset, message ->
          if message.conversation_id do
            AstraplexWeb.Endpoint.broadcast(
              "conversation:messages:#{message.conversation_id}",
              "new_message",
              %{message: message}
            )
          end

          {:ok, message}
        end)
      end,
      on: [:create]
    )
  end

  postgres do
    table("messages")
    repo(Astraplex.Repo)
  end
end
