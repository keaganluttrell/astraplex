defmodule Astraplex.Messaging.ChannelAuthorizationTest do
  @moduledoc false
  use Astraplex.DataCase, async: false

  setup do
    admin = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :admin})
    staff = Astraplex.Factory.insert!(Astraplex.Accounts.User, attrs: %{role: :staff})
    %{admin: admin, staff: staff}
  end

  describe "staff cannot manage channels" do
    test "staff cannot create a channel", %{staff: staff} do
      assert_raise Ash.Error.Forbidden, fn ->
        Ash.create!(Astraplex.Messaging.Channel, %{name: "forbidden"}, actor: staff)
      end
    end

    test "staff cannot update a channel", %{admin: admin, staff: staff} do
      channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "test-chan"}, actor: admin)

      assert_raise Ash.Error.Forbidden, fn ->
        Ash.update!(channel, %{name: "renamed"}, action: :update, actor: staff)
      end
    end

    test "staff cannot archive a channel", %{admin: admin, staff: staff} do
      channel = Ash.create!(Astraplex.Messaging.Channel, %{name: "test-archive"}, actor: admin)

      assert_raise Ash.Error.Forbidden, fn ->
        Ash.update!(channel, %{}, action: :archive, actor: staff)
      end
    end
  end

  describe "non-member read restriction" do
    test "non-member cannot read a channel via default read", %{admin: admin, staff: staff} do
      Ash.create!(Astraplex.Messaging.Channel, %{name: "secret"}, actor: admin)

      channels = Ash.read!(Astraplex.Messaging.Channel, actor: staff)
      assert channels == []
    end
  end
end
