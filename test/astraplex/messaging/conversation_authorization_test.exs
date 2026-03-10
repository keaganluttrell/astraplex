defmodule Astraplex.Messaging.ConversationAuthorizationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  alias Ash.Resource.Info
  alias Astraplex.Messaging.Conversation

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff1 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    non_member = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

    conversation =
      Ash.create!(
        Conversation,
        %{},
        action: :create_with_message,
        actor: staff1,
        arguments: %{member_ids: [staff2.id], body: "Private message"}
      )

    %{
      admin: admin,
      staff1: staff1,
      staff2: staff2,
      non_member: non_member,
      conversation: conversation
    }
  end

  describe "read authorization" do
    test "non-member cannot read conversation", %{non_member: non_member} do
      conversations = Ash.read!(Conversation, actor: non_member)
      assert conversations == []
    end

    test "admin non-member cannot read conversation (no admin bypass)", %{admin: admin} do
      conversations = Ash.read!(Conversation, actor: admin)
      assert conversations == []
    end

    test "member can read their conversations", %{staff1: staff1, conversation: conversation} do
      conversations = Ash.read!(Conversation, actor: staff1)
      assert length(conversations) == 1
      assert hd(conversations).id == conversation.id
    end
  end

  describe "create authorization" do
    test "any active user can create conversation", %{non_member: non_member, staff2: staff2} do
      conversation =
        Ash.create!(
          Conversation,
          %{},
          action: :create_with_message,
          actor: non_member,
          arguments: %{member_ids: [staff2.id], body: "Hello"}
        )

      assert conversation.id
    end
  end

  describe "GRP-04 descoped" do
    test "no leave or destroy action exists on Conversation" do
      actions =
        Conversation
        |> Info.actions()
        |> Enum.map(& &1.name)

      refute :leave in actions
      refute :destroy in actions
    end
  end
end
