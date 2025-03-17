defmodule Value8BetsWeb.Router do
  use Value8BetsWeb, :router

  import Value8BetsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Value8BetsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :require_authenticated_user_live do
    plug :require_authenticated_user
    plug :put_root_layout, html: {Value8BetsWeb.Layouts, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_user
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Value8BetsWeb.Auth.Pipeline
  end

  pipeline :ensure_admin do
    plug Value8BetsWeb.Auth.EnsureRole, "admin"
  end

  pipeline :ensure_superuser do
    plug Value8BetsWeb.Auth.EnsureRole, "superuser"
  end

  # Public browser routes
  scope "/", Value8BetsWeb do
    pipe_through [:browser]

    live_session :default,
      on_mount: [{Value8BetsWeb.UserAuth, :mount_current_user}] do
      live "/", BettingLive.Index, :index
      live "/betting", BettingLive.Index, :index
    end

    # Authentication routes
    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  # Protected routes that require authentication
  scope "/", Value8BetsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{Value8BetsWeb.UserAuth, :ensure_authenticated}] do
      live "/betting/:id/place-bet", BettingLive.PlaceBet, :new
      live "/betting/history", BettingLive.History, :index
    end

    get "/users/settings", UserSettingsController, :edit
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:value8_bets, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Value8BetsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Update the admin scope to remove authentication requirements
  scope "/admin", Value8BetsWeb do
    pipe_through [:browser]

    live_session :admin do
      live "/", AdminLive.Dashboard, :index
      live "/users", AdminLive.Dashboard, :index
      live "/users/:id", AdminLive.UserDetail, :show
    end
  end

  # Public API routes
  scope "/api", Value8BetsWeb do
    pipe_through :api

    post "/users/login", AuthController, :login
    post "/users/register", UserRegistrationController, :create_api
    get "/games", BettingController, :index
  end

  # Protected API routes
  scope "/api", Value8BetsWeb do
    pipe_through [:api_auth]

    get "/get_user", UserController, :get_user

    # Betting routes
    get "/betting/history", BettingController, :history
    get "/betting/:id", BettingController, :show
    get "/betting/:id/place-bet", BettingController, :get_bet_details
    post "/betting/:id/place-bet", BettingController, :place_bet
    get "/user/bets", BettingController, :user_bets

    # Admin only routes
    scope "/admin" do
      pipe_through [:ensure_admin]

      get "/dashboard", AdminController, :dashboard
      get "/users", AdminController, :list_users
      get "/users/:id", AdminController, :user_details
      get "/profits", AdminController, :profits
      post "/games", AdminController, :create_game
      put "/games/:id", AdminController, :update_game
      delete "/users/:id", AdminController, :soft_delete_user
    end

    # Superuser only routes
    scope "/admin" do
      pipe_through [:ensure_superuser]

      delete "/users/:id", AdminController, :delete_user
      put "/users/:id/toggle-admin", AdminController, :toggle_admin
    end
  end

  # Admin API routes
  scope "/api/admin", Value8BetsWeb do
    pipe_through [:api_auth, :ensure_superuser]

    post "/users/register", AdminController, :register_admin
    # ... other admin routes ...
  end
end
