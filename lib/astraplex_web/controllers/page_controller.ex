defmodule AstraplexWeb.PageController do
  use AstraplexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
