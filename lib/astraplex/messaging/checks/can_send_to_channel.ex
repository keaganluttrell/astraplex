defmodule Astraplex.Messaging.Checks.CanSendToChannel do
  @moduledoc "Custom policy check that verifies the actor is a member of an active channel."

  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_options) do
    "actor is a member of the target channel and channel is active"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _options) do
    channel_id = Ash.Changeset.get_attribute(changeset, :channel_id)

    case channel_id do
      nil ->
        false

      channel_id ->
        with {:ok, channel} <-
               Ash.get(Astraplex.Messaging.Channel, channel_id, authorize?: false),
             true <- channel.status == :active,
             {:ok, memberships} <-
               Astraplex.Messaging.Membership
               |> Ash.Query.filter(channel_id == ^channel_id and user_id == ^actor.id)
               |> Ash.read(authorize?: false) do
          memberships != []
        else
          _ -> false
        end
    end
  end
end
