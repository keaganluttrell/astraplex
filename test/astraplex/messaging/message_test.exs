defmodule Astraplex.Messaging.MessageTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "msg-channel"}, actor: admin)

    Ash.create!(
      Astraplex.Messaging.Membership,
      %{channel_id: channel.id, user_id: staff.id},
      actor: admin
    )

    %{admin: admin, staff: staff, channel: channel}
  end

  describe "send_message" do
    test "member sends message to channel", %{staff: staff, channel: channel} do
      message =
        Ash.create!(
          Astraplex.Messaging.Message,
          %{body: "Hello world", channel_id: channel.id},
          action: :send_message,
          actor: staff
        )

      assert message.body == "Hello world"
      assert message.channel_id == channel.id
      assert message.sender_id == staff.id
    end

    test "cannot send message to archived channel", %{
      admin: admin,
      staff: staff,
      channel: channel
    } do
      Ash.update!(channel, %{}, action: :archive, actor: admin)

      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(
          Astraplex.Messaging.Message,
          %{body: "Should fail", channel_id: channel.id},
          action: :send_message,
          actor: staff
        )
      end
    end
  end

  describe "read messages" do
    test "member reads messages in their channel", %{staff: staff, channel: channel} do
      Ash.create!(
        Astraplex.Messaging.Message,
        %{body: "First message", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      Ash.create!(
        Astraplex.Messaging.Message,
        %{body: "Second message", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      messages = Ash.read!(Astraplex.Messaging.Message, actor: staff)
      assert length(messages) == 2
    end

    test "new member can read all prior messages", %{admin: admin, staff: staff, channel: channel} do
      Ash.create!(
        Astraplex.Messaging.Message,
        %{body: "Before new member", channel_id: channel.id},
        action: :send_message,
        actor: staff
      )

      new_staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})

      Ash.create!(
        Astraplex.Messaging.Membership,
        %{channel_id: channel.id, user_id: new_staff.id},
        actor: admin
      )

      messages = Ash.read!(Astraplex.Messaging.Message, actor: new_staff)
      assert length(messages) == 1
      assert hd(messages).body == "Before new member"
    end
  end
end
