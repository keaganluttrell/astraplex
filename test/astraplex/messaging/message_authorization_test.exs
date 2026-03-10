defmodule Astraplex.Messaging.MessageAuthorizationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

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

  describe "non-member restrictions" do
    test "non-member cannot send message to channel", %{non_member: non_member, channel: channel} do
      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(
          Astraplex.Messaging.Message,
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
        Astraplex.Messaging.Message,
        %{body: "Secret message", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      messages = Ash.read!(Astraplex.Messaging.Message, actor: non_member)
      assert messages == []
    end
  end
end
