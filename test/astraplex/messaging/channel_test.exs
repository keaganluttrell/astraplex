defmodule Astraplex.Messaging.ChannelTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    %{admin: admin, staff: staff}
  end

  describe "create" do
    test "admin creates channel with name and description", %{admin: admin} do
      channel =
        Ash.create!(Astraplex.Messaging.Channel, %{name: "general", description: "General chat"},
          actor: admin
        )

      assert to_string(channel.name) == "general"
      assert channel.description == "General chat"
      assert channel.status == :active
    end

    test "channel name uniqueness enforced (case-insensitive)", %{admin: admin} do
      Ash.create!(Astraplex.Messaging.Channel, %{name: "General"}, actor: admin)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.create!(Astraplex.Messaging.Channel, %{name: "general"}, actor: admin)
      end
    end
  end

  describe "update" do
    test "admin updates channel name and description", %{admin: admin} do
      channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "old-name"}, actor: admin)

      updated =
        Ash.update!(channel, %{name: "new-name", description: "Updated"},
          action: :update,
          actor: admin
        )

      assert to_string(updated.name) == "new-name"
      assert updated.description == "Updated"
    end
  end

  describe "archive" do
    test "admin archives channel", %{admin: admin} do
      channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "to-archive"}, actor: admin)

      archived = Ash.update!(channel, %{}, action: :archive, actor: admin)

      assert archived.status == :archived
    end
  end

  describe "list_for_user" do
    test "returns only channels the user is a member of", %{admin: admin, staff: staff} do
      channel1 = Ash.create!(Astraplex.Messaging.Channel, %{name: "alpha"}, actor: admin)
      _channel2 = Ash.create!(Astraplex.Messaging.Channel, %{name: "beta"}, actor: admin)

      Ash.create!(Astraplex.Messaging.Membership, %{channel_id: channel1.id, user_id: staff.id},
        actor: admin
      )

      channels =
        Ash.read!(Astraplex.Messaging.Channel, action: :list_for_user, actor: staff)

      assert length(channels) == 1
      assert hd(channels).id == channel1.id
    end

    test "excludes archived channels", %{admin: admin, staff: staff} do
      channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "archived-chan"}, actor: admin)

      Ash.create!(Astraplex.Messaging.Membership, %{channel_id: channel.id, user_id: staff.id},
        actor: admin
      )

      Ash.update!(channel, %{}, action: :archive, actor: admin)

      channels =
        Ash.read!(Astraplex.Messaging.Channel, action: :list_for_user, actor: staff)

      assert channels == []
    end
  end
end
