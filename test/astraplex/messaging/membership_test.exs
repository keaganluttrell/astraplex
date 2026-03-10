defmodule Astraplex.Messaging.MembershipTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "test-channel"}, actor: admin)
    %{admin: admin, staff: staff, channel: channel}
  end

  describe "create" do
    test "admin adds user to channel", %{admin: admin, staff: staff, channel: channel} do
      membership =
        Ash.create!(
          Astraplex.Messaging.Membership,
          %{channel_id: channel.id, user_id: staff.id},
          actor: admin
        )

      assert membership.channel_id == channel.id
      assert membership.user_id == staff.id
    end

    test "duplicate membership rejected", %{admin: admin, staff: staff, channel: channel} do
      Ash.create!(
        Astraplex.Messaging.Membership,
        %{channel_id: channel.id, user_id: staff.id},
        actor: admin
      )

      assert_raise Ash.Error.Invalid, fn ->
        Ash.create!(
          Astraplex.Messaging.Membership,
          %{channel_id: channel.id, user_id: staff.id},
          actor: admin
        )
      end
    end
  end

  describe "destroy" do
    test "admin removes user from channel", %{admin: admin, staff: staff, channel: channel} do
      membership =
        Ash.create!(
          Astraplex.Messaging.Membership,
          %{channel_id: channel.id, user_id: staff.id},
          actor: admin
        )

      assert :ok = Ash.destroy!(membership, actor: admin)
    end
  end
end
