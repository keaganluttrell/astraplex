defmodule Astraplex.Messaging.Checks.CanSendToConversation do
  @moduledoc "Custom policy check that verifies the actor is a member of a conversation."

  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_options) do
    "actor is a member of the target conversation"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _options) do
    conversation_id = Ash.Changeset.get_attribute(changeset, :conversation_id)

    case conversation_id do
      nil ->
        false

      conversation_id ->
        case Astraplex.Messaging.ConversationMembership
             |> Ash.Query.filter(conversation_id == ^conversation_id and user_id == ^actor.id)
             |> Ash.read(authorize?: false) do
          {:ok, memberships} -> memberships != []
          _ -> false
        end
    end
  end
end
