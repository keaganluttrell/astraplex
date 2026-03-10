defmodule AstraplexWeb.Router do
  use AstraplexWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AstraplexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Unauthenticated routes (sign-in page, auth callbacks)
  scope "/", AstraplexWeb do
    pipe_through :browser

    sign_in_route(path: "/sign-in", live_view: AstraplexWeb.AuthLive.SignInLive)
    sign_out_route(AuthController)
    auth_routes(AuthController, Astraplex.Accounts.User, path: "/auth")
  end

  # Authenticated routes
  scope "/", AstraplexWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated,
      on_mount: [{AstraplexWeb.LiveAuth, :require_authenticated_user}] do
      live "/", DashboardLive, :index
    end
  end

  # Admin routes
  scope "/admin", AstraplexWeb.Admin do
    pipe_through :browser

    ash_authentication_live_session :admin,
      on_mount: [{AstraplexWeb.LiveAuth, :require_admin}] do
      live "/users", UserListLive, :index
      live "/users/new", UserListLive, :new
    end
  end

  scope "/mcp" do
    forward "/", AshAi.Mcp.Router,
      tools: [:check_health],
      protocol_version_statement: "2024-11-05",
      otp_app: :astraplex
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:astraplex, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AstraplexWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
