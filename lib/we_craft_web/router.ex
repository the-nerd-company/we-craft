defmodule WeCraftWeb.Router do
  use WeCraftWeb, :router

  import WeCraftWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  defp admin_basic_auth(conn, _opts) do
    username = "admin"
    password = "7pvDVP60GNbCMe4sxpSRtEHlb"
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WeCraftWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
  end

  # Other scopes may use custom stacks.
  scope "/api", WeCraftWeb do
    pipe_through [:api, :require_authenticated_user]

    post "/v1/pages/:page_id/files", Api.V1.Pages.FileController, :create
    get "/v1/pages/:page_id/files/:file_name", Api.V1.Pages.FileController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:we_craft, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/admin/" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: WeCraftWeb.Telemetry
  end

  scope "/", WeCraftWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{WeCraftWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :index
      live "/profile/edit", Profiles.EditProfile, :edit
      live "/projects/new", Projects.NewProject, :show
      live "/my-projects", Projects.MyProjects, :index
      live "/project/:project_id/pages/new", Pages.NewPage, :create
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", WeCraftWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{WeCraftWeb.UserAuth, :mount_current_scope}] do
      live "/", Home, :index
      live "/feed", Feed, :index
      live "/profiles", Profiles.Profiles, :index
      live "/dms", ListDm, :index
      live "/dms/:chat_id", Dm, :show
      live "/profile/:user_id", Profiles.ShowProfile, :show
      live "/project/:project_id/channels", Projects.Project, :show
      live "/project/:project_id/channels/:channel_id/meeting", Projects.Meeting, :show

      live "/project/:project_id", Projects.ProjectInfo, :info
      live "/project/:project_id/pages/:page_id", Pages.Page, :show

      live "/project/:project_id/tickets", Projects.Tickets.CustomersTicket, :index
      live "/project/:project_id/tickets/new", Projects.Tickets.NewCustomerTicket, :new
      live "/project/:project_id/tickets/:ticket_id", Projects.Tickets.ShowCustomerTicket, :show

      live "/project/:project_id/edit", Projects.EditProject, :edit
      live "/project/:project_id/customers", Projects.CRM.Customers, :index
      live "/project/:project_id/customers/new", Projects.CRM.NewCustomer, :new
      live "/project/:project_id/customers/:customer_id/edit", Projects.CRM.EditCustomer, :edit
      live "/project/:project_id/milestones", Projects.Milestones.Milestones, :index
      live "/project/:project_id/milestones/new", Projects.Milestones.NewMilestone, :new

      live "/project/:project_id/milestones/:milestone_id/edit",
           Projects.Milestones.EditMilestone,
           :edit

      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    get "/health", HealthController, :check
    get "/telemetry-test", TestTelemetryController, :test
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
