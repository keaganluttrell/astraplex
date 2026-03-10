defmodule Astraplex.Messaging.MessageAuthorizationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  alias Astraplex.Messaging.Conversation
  alias Astraplex.Messaging.Message

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    non_member = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "auth-msg-channel"}, actor: admin)

    Ash.create!(
      Astraplex.Messaging.Membership,
      %{channel_id: channel.id, user_id: staff.id},
      actor: admin
    )

    %{admin: admin, staff: staff, non_member: non_member, channel: channel}
  end

  describe "channel message restrictions" do
    test "non-member cannot send message to channel", %{non_member: non_member, channel: channel} do
      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(
          Message,
          %{body: "Should fail", channel_id: channel.id},
          action: :send_message,
          actor: non_member
        )
      end
    end

    test "non-member cannot read messages in channel", %{
      staff: staff,
      non_member: non_member,
      channel: channel
    } do
      Ash.create!(
        Message,
        %{body: "Secret message", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      messages = Ash.read!(Message, actor: non_member)
      assert messages == []
    end

    test "admin can read channel messages", %{admin: admin, staff: staff, channel: channel} do
      Ash.create!(
        Message,
        %{body: "Admin visible", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      messages = Ash.read!(Message, actor: admin)
      channel_messages = Enum.filter(messages, &(&1.channel_id == channel.id))
      assert length(channel_messages) == 1
    end
  end

  describe "conversation message restrictions" do
    test "non-member cannot send message to conversation", %{
      staff: staff,
      non_member: non_member
    } do
      staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

      conversation =
        Ash.create!(
          Conversation,
          %{member_ids: [staff2.id], body: "Private"},
          action: :create_with_message,
          actor: staff
        )

      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(
          Message,
          %{body: "Should fail", conversation_id: conversation.id},
          action: :send_conversation_message,
          actor: non_member
        )
      end
    end

    test "conversation member can send message", %{staff: staff} do
      staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

      conversation =
        Ash.create!(
          Conversation,
          %{member_ids: [staff2.id], body: "Initial"},
          action: :create_with_message,
          actor: staff
        )

      message =
        Ash.create!(
          Message,
          %{body: "Reply", conversation_id: conversation.id},
          action: :send_conversation_message,
          actor: staff
        )

      assert message.body == "Reply"
    end

    test "admin non-member cannot read conversation messages", %{admin: admin, staff: staff} do
      staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

      conversation =
        Ash.create!(
          Conversation,
          %{member_ids: [staff2.id], body: "Private convo"},
          action: :create_with_message,
          actor: staff
        )

      Ash.create!(
        Message,
        %{body: "Secret follow-up", conversation_id: conversation.id},
        action: :send_conversation_message,
        actor: staff
      )

      messages = Ash.read!(Message, actor: admin)
      conversation_messages = Enum.filter(messages, &(&1.conversation_id == conversation.id))
      assert conversation_messages == []
    end

    test "conversation member can read conversation messages", %{staff: staff} do
      staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

      conversation =
        Ash.create!(
          Conversation,
          %{member_ids: [staff2.id], body: "Readable"},
          action: :create_with_message,
          actor: staff
        )

      messages = Ash.read!(Message, actor: staff2)
      conversation_messages = Enum.filter(messages, &(&1.conversation_id == conversation.id))
      assert length(conversation_messages) == 1
    end
  end
end
