defmodule Astraplex.Messaging.MembershipAuthorizationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    staff2 = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "auth-channel"}, actor: admin)
    %{admin: admin, staff: staff, staff2: staff2, channel: channel}
  end

  describe "staff cannot manage memberships" do
    test "staff cannot add member", %{staff: staff, staff2: staff2, channel: channel} do
      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(
          Astraplex.Messaging.Membership,
          %{channel_id: channel.id, user_id: staff2.id},
          actor: staff
        )
      end
    end

    test "staff cannot remove member", %{admin: admin, staff: staff, channel: channel} do
      membership =
        Ash.create!(
          Astraplex.Messaging.Membership,
          %{channel_id: channel.id, user_id: staff.id},
          actor: admin
        )

      assert_raise Ash.Error.Forbidden, fn ->
        Ash.destroy!(membership, actor: staff)
      end
    end
  end

  describe "membership read policies" do
    test "member can read membership list for their channel", %{
      admin: admin,
      staff: staff,
      channel: channel
    } do
      Ash.create!(
        Astraplex.Messaging.Membership,
        %{channel_id: channel.id, user_id: staff.id},
        actor: admin
      )

      memberships = Ash.read!(Astraplex.Messaging.Membership, actor: staff)
      assert length(memberships) == 1
    end

    test "non-member cannot read membership list for channel they are not in", %{
      admin: admin,
      staff: staff,
      staff2: staff2,
      channel: channel
    } do
      Ash.create!(
        Astraplex.Messaging.Membership,
        %{channel_id: channel.id, user_id: staff.id},
        actor: admin
      )

      memberships = Ash.read!(Astraplex.Messaging.Membership, actor: staff2)
      assert memberships == []
    end
  end
end
