defmodule AstraplexWeb.Components.DesignSystemTest do
  @moduledoc false
  use AstraplexWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "button component renders with btn class" do
    html =
      render_component(&DaisyUIComponents.Button.button/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Test" end}]
      )

    assert html =~ "btn"
    assert html =~ "Test"
  end

  test "badge component renders with badge class" do
    html =
      render_component(&DaisyUIComponents.Badge.badge/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Status" end}]
      )

    assert html =~ "badge"
    assert html =~ "Status"
  end

  test "card component renders with card class" do
    html =
      render_component(&DaisyUIComponents.Card.card/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Content" end}]
      )

    assert html =~ "card"
    assert html =~ "Content"
  end

  test "corporate theme is set in root layout" do
    html = File.read!("lib/astraplex_web/components/layouts/root.html.heex")
    assert html =~ ~s(data-theme="corporate")
  end

  test "DaisyUIComponents is available in web module" do
    source = File.read!("lib/astraplex_web.ex")
    assert source =~ "use DaisyUIComponents"
  end
end
