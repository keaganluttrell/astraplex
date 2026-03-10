defmodule Astraplex.Messaging.Conversation do
  @moduledoc "Conversation resource for DMs and group messages with member-set uniqueness."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Messaging

  attributes do
    uuid_primary_key(:id)

    attribute(:member_hash, :string,
      allow_nil?: false,
      public?: true
    )

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_member_set, [:member_hash])
  end

  relationships do
    has_many :conversation_memberships, Astraplex.Messaging.ConversationMembership
    has_many :messages, Astraplex.Messaging.Message

    many_to_many :members, Astraplex.Accounts.User do
      through(Astraplex.Messaging.ConversationMembership)
      source_attribute_on_join_resource(:conversation_id)
      destination_attribute_on_join_resource(:user_id)
    end
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:member_hash])
    end

    create :create_with_message do
      accept([])

      argument :member_ids, {:array, :uuid} do
        allow_nil?(false)
      end

      argument :body, :string do
        allow_nil?(false)
      end

      change(fn changeset, context ->
        actor = context.actor
        member_ids = Ash.Changeset.get_argument(changeset, :member_ids)
        all_member_ids = Enum.uniq([actor.id | member_ids])

        member_hash =
          all_member_ids
          |> Enum.sort()
          |> Enum.join(",")
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)

        changeset
        |> Ash.Changeset.force_change_attribute(:member_hash, member_hash)
        |> Ash.Changeset.after_action(fn _changeset, conversation ->
          body = Ash.Changeset.get_argument(changeset, :body)

          # Create memberships for all members
          Enum.each(all_member_ids, fn user_id ->
            Ash.create!(
              Astraplex.Messaging.ConversationMembership,
              %{conversation_id: conversation.id, user_id: user_id},
              authorize?: false
            )
          end)

          # Create first message
          Ash.create!(
            Astraplex.Messaging.Message,
            %{body: body, conversation_id: conversation.id},
            action: :send_conversation_message,
            actor: actor
          )

          {:ok, conversation}
        end)
      end)
    end

    read :list_for_user do
      filter(expr(exists(conversation_memberships, user_id == ^actor(:id))))
      prepare(build(sort: [updated_at: :desc], load: [:members]))
    end

    read :find_by_member_hash do
      get_by([:member_hash])
    end

    update :touch do
      accept([])
      change(set_attribute(:updated_at, &DateTime.utc_now/0))
    end
  end

  policies do
    policy action(:create_with_message) do
      authorize_if(actor_present())
    end

    policy action(:create) do
      authorize_if(actor_present())
    end

    policy action(:read) do
      authorize_if(expr(exists(conversation_memberships, user_id == ^actor(:id))))
    end

    policy action(:list_for_user) do
      authorize_if(always())
    end

    policy action(:find_by_member_hash) do
      authorize_if(actor_present())
    end

    policy action(:touch) do
      authorize_if(expr(exists(conversation_memberships, user_id == ^actor(:id))))
    end
  end

  postgres do
    table("conversations")
    repo(Astraplex.Repo)
  end
end
