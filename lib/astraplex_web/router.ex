defmodule AstraplexWeb.Router do
  use AstraplexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AstraplexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AstraplexWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/mcp" do
    forward "/", AshAi.Mcp.Router,
      tools: [:check_health],
      protocol_version_statement: "2024-11-05",
      otp_app: :astraplex
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:astraplex, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AstraplexWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
