defmodule AstraplexWeb.Components.UITest do
  use AstraplexWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AstraplexWeb.Components.UI

  defp render_ui(component, assigns) do
    render_component(component, assigns)
  end

  describe "page_header/1" do
    test "renders title text" do
      html = render_ui(&UI.page_header/1, title: "Dashboard")

      assert html =~ "Dashboard"
      assert html =~ "text-xl font-bold"
    end

    test "renders actions slot content" do
      html =
        render_component(&UI.page_header/1,
          title: "Users",
          actions: [
            %{__slot__: :actions, inner_block: fn _, _ -> "Add User" end}
          ]
        )

      assert html =~ "Users"
      assert html =~ "Add User"
    end
  end

  describe "empty_state/1" do
    test "renders title and description" do
      html =
        render_ui(&UI.empty_state/1,
          title: "No messages",
          description: "Start a conversation to see messages here"
        )

      assert html =~ "No messages"
      assert html =~ "Start a conversation to see messages here"
    end

    test "renders icon when provided" do
      html =
        render_ui(&UI.empty_state/1,
          title: "No messages",
          icon: "hero-inbox"
        )

      assert html =~ "hero-inbox"
    end
  end

  describe "user_avatar/1" do
    test "generates consistent initials from email" do
      user = %{id: Ash.UUID.generate(), email: "test@example.com"}
      html = render_ui(&UI.user_avatar/1, user: user)

      assert html =~ "TE"
    end

    test "generates deterministic colors for same user ID" do
      id = Ash.UUID.generate()
      user = %{id: id, email: "alice@example.com"}

      html1 = render_ui(&UI.user_avatar/1, user: user)
      html2 = render_ui(&UI.user_avatar/1, user: user)

      assert html1 == html2
    end

    test "supports size variants" do
      user = %{id: Ash.UUID.generate(), email: "test@example.com"}

      xs_html = render_ui(&UI.user_avatar/1, user: user, size: "xs")
      lg_html = render_ui(&UI.user_avatar/1, user: user, size: "lg")

      assert xs_html =~ "w-6 h-6"
      assert lg_html =~ "w-14 h-14"

      assert xs_html =~ "text-xs"
      assert lg_html =~ "text-lg"
    end
  end

  describe "breadcrumb/1" do
    test "renders all path segments" do
      html =
        render_ui(&UI.breadcrumb/1,
          path: [{"Astraplex", "/"}, {"Admin", "/admin/users"}, {"Users", nil}]
        )

      assert html =~ "Astraplex"
      assert html =~ "Admin"
      assert html =~ "Users"
    end

    test "first and intermediate items are links" do
      html =
        render_ui(&UI.breadcrumb/1,
          path: [{"Astraplex", "/"}, {"Admin", "/admin/users"}, {"Users", nil}]
        )

      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/admin/users")
    end

    test "last item is plain text, not a link" do
      html =
        render_ui(&UI.breadcrumb/1,
          path: [{"Astraplex", "/"}, {"Users", nil}]
        )

      # "Users" should be in a span, not a link
      assert html =~ "<span>Users</span>"
    end

    test "uses daisyUI breadcrumbs class" do
      html =
        render_ui(&UI.breadcrumb/1,
          path: [{"Astraplex", "/"}, {"Home", nil}]
        )

      assert html =~ "breadcrumbs"
    end
  end

  describe "skeleton_list/1" do
    test "renders 5 skeleton rows" do
      html = render_ui(&UI.skeleton_list/1, %{})

      # Each row has a rounded-full circle skeleton
      assert length(Regex.scan(~r/skeleton.*rounded-full/, html)) == 5
    end
  end

  describe "skeleton_card/1" do
    test "renders skeleton rectangle" do
      html = render_ui(&UI.skeleton_card/1, %{})

      assert html =~ "skeleton"
      assert html =~ "rounded-lg"
    end
  end
end
