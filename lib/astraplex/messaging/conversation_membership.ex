defmodule Astraplex.Messaging.ConversationMembership do
  @moduledoc "Membership join resource linking users to conversations."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)
    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :conversation, Astraplex.Messaging.Conversation, allow_nil?: false
    belongs_to :user, Astraplex.Accounts.User, allow_nil?: false
  end

  identities do
    identity(:unique_conversation_membership, [:conversation_id, :user_id])
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:conversation_id, :user_id])
    end
  end

  policies do
    policy action(:create) do
      authorize_if(actor_present())
    end

    policy action(:read) do
      authorize_if(expr(exists(conversation.conversation_memberships, user_id == ^actor(:id))))
    end
  end

  postgres do
    table("conversation_memberships")
    repo(Astraplex.Repo)
  end
end
