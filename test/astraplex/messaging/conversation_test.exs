defmodule Astraplex.Messaging.ConversationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  alias Astraplex.Messaging.Conversation
  alias Astraplex.Messaging.ConversationMembership

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff1 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    staff3 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

    %{admin: admin, staff1: staff1, staff2: staff2, staff3: staff3}
  end

  describe "create_with_message" do
    test "creates conversation with memberships and first message", %{
      staff1: staff1,
      staff2: staff2
    } do
      conversation =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id], body: "Hey there!"}
        )

      assert conversation.id
      assert conversation.member_hash

      # Both users should be members
      memberships = Ash.read!(ConversationMembership, actor: staff1)

      conversation_memberships =
        Enum.filter(memberships, &(&1.conversation_id == conversation.id))

      assert length(conversation_memberships) == 2

      member_user_ids = Enum.map(conversation_memberships, & &1.user_id) |> Enum.sort()
      assert member_user_ids == Enum.sort([staff1.id, staff2.id])

      # First message should exist
      messages = Ash.read!(Astraplex.Messaging.Message, actor: staff1)

      conversation_messages =
        Enum.filter(messages, &(&1.conversation_id == conversation.id))

      assert length(conversation_messages) == 1
      assert hd(conversation_messages).body == "Hey there!"
      assert hd(conversation_messages).sender_id == staff1.id
    end

    test "creates DM conversation with 2 members", %{staff1: staff1, staff2: staff2} do
      conversation =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id], body: "DM message"}
        )

      memberships = Ash.read!(ConversationMembership, actor: staff1)

      conversation_memberships =
        Enum.filter(memberships, &(&1.conversation_id == conversation.id))

      assert length(conversation_memberships) == 2
    end

    test "creates group conversation with 3+ members", %{
      staff1: staff1,
      staff2: staff2,
      staff3: staff3
    } do
      conversation =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id, staff3.id], body: "Group message"}
        )

      memberships = Ash.read!(ConversationMembership, actor: staff1)

      conversation_memberships =
        Enum.filter(memberships, &(&1.conversation_id == conversation.id))

      assert length(conversation_memberships) == 3
    end
  end

  describe "member_hash uniqueness" do
    test "second create with same members raises identity error", %{
      staff1: staff1,
      staff2: staff2
    } do
      Ash.create!(
        Conversation,
        %{},
        action: :create_with_message,
        actor: staff1,
        arguments: %{member_ids: [staff2.id], body: "First message"}
      )

      assert_raise Ash.Error.Invalid, fn ->
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id], body: "Duplicate"}
        )
      end
    end
  end

  describe "find_by_member_hash" do
    test "returns existing conversation by member hash", %{staff1: staff1, staff2: staff2} do
      conversation =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id], body: "Find me"}
        )

      found =
        Ash.read_one!(
          Conversation,
          action: :find_by_member_hash,
          actor: staff1,
          query: [filter: [member_hash: conversation.member_hash]]
        )

      assert found.id == conversation.id
    end
  end

  describe "list_for_user" do
    test "returns only conversations where actor is a member", %{
      staff1: staff1,
      staff2: staff2,
      staff3: staff3
    } do
      Ash.create!(
        Conversation,
        %{},
        action: :create_with_message,
        actor: staff1,
        arguments: %{member_ids: [staff2.id], body: "Convo 1"}
      )

      # staff3 creates a separate conversation with staff2 (staff1 NOT a member)
      Ash.create!(
        Conversation,
        %{},
        action: :create_with_message,
        actor: staff3,
        arguments: %{member_ids: [staff2.id], body: "Convo 2"}
      )

      conversations =
        Ash.read!(Conversation, action: :list_for_user, actor: staff1)

      assert length(conversations) == 1
    end

    test "sorts by updated_at desc", %{
      staff1: staff1,
      staff2: staff2,
      staff3: staff3
    } do
      convo1 =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff2.id], body: "First convo"}
        )

      Process.sleep(10)

      convo2 =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: staff1,
          arguments: %{member_ids: [staff3.id], body: "Second convo"}
        )

      conversations =
        Ash.read!(Conversation, action: :list_for_user, actor: staff1)

      assert length(conversations) == 2
      # Most recent first
      assert hd(conversations).id == convo2.id
      assert List.last(conversations).id == convo1.id
    end
  end
end
